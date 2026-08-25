import { readFileSync } from 'node:fs';
import { after, before, describe, it } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc, updateDoc } from 'firebase/firestore';

let env;

const PATIENT = 'patient-1';
const CLINICIAN = 'clinician-1';
const STRANGER = 'stranger-1';
const APPT = 'appt-1';

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-abilitylink',
    firestore: {
      host: '127.0.0.1',
      port: 8080,
      rules: readFileSync('../firestore.rules', 'utf8'),
    },
  });

  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'providers/prov-1'), { ownerUid: CLINICIAN, name: 'Clinic' });
    await setDoc(doc(db, 'appointments', APPT), {
      uid: PATIENT,
      providerId: 'prov-1',
      status: 'booked',
    });
    await setDoc(doc(db, 'consultJoinCodes/ABC123'), {
      appointmentId: APPT,
      uid: PATIENT,
    });
    await setDoc(doc(db, 'passportShares/share-1'), {
      ownerUid: PATIENT,
      status: 'active',
      consent: true,
      snapshot: { conditions: 'asthma' },
      expiresAt: new Date(Date.now() + 86400000),
    });
    await setDoc(doc(db, 'passportShares/share-expired'), {
      ownerUid: PATIENT,
      status: 'active',
      consent: true,
      snapshot: { conditions: 'asthma' },
      expiresAt: new Date(Date.now() - 1000),
    });
    await setDoc(doc(db, 'enquiries/enq-1'), { uid: PATIENT, providerId: 'prov-1' });
    await setDoc(doc(db, 'employers/emp-owned'), {
      ownerUid: CLINICIAN,
      name: 'Owned Co',
      verified: false,
    });
    await setDoc(doc(db, 'barrierAlerts/alert-1'), {
      uid: PATIENT,
      status: 'open',
      title: 'Broken lift',
    });
    await setDoc(doc(db, 'sessionChats/session-appt-1'), {
      participants: [PATIENT],
      appointmentId: APPT,
    });
    await setDoc(doc(db, 'sessionChats/session-appt-1/messages/m1'), {
      uid: PATIENT,
      body: 'my knee hurts',
    });
  });
});

after(async () => {
  await env.cleanup();
});

const asPatient = () => env.authenticatedContext(PATIENT).firestore();
const asClinician = () => env.authenticatedContext(CLINICIAN).firestore();
const asStranger = () => env.authenticatedContext(STRANGER).firestore();
const asAnon = () => env.unauthenticatedContext().firestore();

describe('passport shares', () => {
  it('cannot be read without signing in', async () => {
    await assertFails(getDoc(doc(asAnon(), 'passportShares/share-1')));
  });

  it('can be read by the owner', async () => {
    await assertSucceeds(getDoc(doc(asPatient(), 'passportShares/share-1')));
  });

  it('can be read by a signed-in code holder', async () => {
    await assertSucceeds(getDoc(doc(asStranger(), 'passportShares/share-1')));
  });

  it('cannot be read once expired', async () => {
    await assertFails(getDoc(doc(asStranger(), 'passportShares/share-expired')));
  });
});

describe('passport access logs', () => {
  it('cannot be forged against an unrelated owner', async () => {
    await assertFails(
      setDoc(doc(asStranger(), 'passportAccessLogs/forged'), {
        ownerUid: STRANGER,
        shareId: 'share-1',
        viewerUid: STRANGER,
        action: 'viewed',
      }),
    );
  });

  it('records the real owner of the share', async () => {
    await assertSucceeds(
      setDoc(doc(asStranger(), 'passportAccessLogs/real'), {
        ownerUid: PATIENT,
        shareId: 'share-1',
        viewerUid: STRANGER,
        action: 'viewed',
      }),
    );
  });
});

describe('consult rooms', () => {
  const session = 'consultRooms/appt-1/call/session';

  it('are closed to unrelated users', async () => {
    await assertFails(setDoc(doc(asStranger(), session), { offer: 'sdp' }));
    await assertFails(getDoc(doc(asStranger(), session)));
  });

  it('are open to the patient', async () => {
    await assertSucceeds(setDoc(doc(asPatient(), session), { offer: 'sdp' }));
  });

  it('are open to the clinician who owns the provider', async () => {
    await assertSucceeds(getDoc(doc(asClinician(), session)));
  });

  it('let a code holder register as a guest and then signal', async () => {
    const db = asStranger();
    await assertSucceeds(
      setDoc(doc(db, `consultRooms/${APPT}/guests/${STRANGER}`), { code: 'ABC123' }),
    );
    await assertSucceeds(getDoc(doc(db, session)));
  });

  it('reject guest registration with a code for another visit', async () => {
    await assertFails(
      setDoc(doc(asStranger(), 'consultRooms/other-appt/guests/' + STRANGER), {
        code: 'ABC123',
      }),
    );
  });
});

describe('notifications', () => {
  it('cannot be injected into another inbox anonymously', async () => {
    await assertFails(
      setDoc(doc(asStranger(), 'notifications/forged'), {
        uid: PATIENT,
        type: 'payment',
        title: 'Send money here',
        body: 'scam',
        read: false,
      }),
    );
  });

  it('cannot arrive already read', async () => {
    await assertFails(
      setDoc(doc(asStranger(), 'notifications/preread'), {
        uid: PATIENT,
        createdBy: STRANGER,
        type: 'message',
        title: 'hi',
        body: 'hi',
        read: true,
      }),
    );
  });

  it('allow an attributable cross-user message', async () => {
    await assertSucceeds(
      setDoc(doc(asStranger(), 'notifications/legit'), {
        uid: PATIENT,
        createdBy: STRANGER,
        type: 'message',
        title: 'New session message',
        body: 'hello',
        read: false,
      }),
    );
  });

  it('allow self notifications', async () => {
    await assertSucceeds(
      setDoc(doc(asPatient(), 'notifications/mine'), {
        uid: PATIENT,
        type: 'nearby',
        title: 'Accessible place nearby',
        body: 'x',
        read: false,
      }),
    );
  });
});

describe('invoices', () => {
  it('cannot be forged against another user', async () => {
    await assertFails(
      setDoc(doc(asStranger(), 'invoices/forged'), {
        uid: PATIENT,
        type: 'lead_fee',
        amountCents: 9900,
        status: 'due',
        relatedId: 'enq-1',
      }),
    );
  });

  it('cannot bill a lead fee from an enquiry you did not make', async () => {
    await assertFails(
      setDoc(doc(asStranger(), 'invoices/no-enquiry'), {
        uid: CLINICIAN,
        createdBy: STRANGER,
        type: 'lead_fee',
        amountCents: 500,
        status: 'due',
        relatedId: 'enq-1',
      }),
    );
  });

  it('allow a lead fee derived from your own enquiry', async () => {
    await assertSucceeds(
      setDoc(doc(asPatient(), 'invoices/lead'), {
        uid: CLINICIAN,
        createdBy: PATIENT,
        type: 'lead_fee',
        amountCents: 500,
        status: 'due',
        relatedId: 'enq-1',
      }),
    );
  });

  it('allow a commission derived from your own appointment', async () => {
    await assertSucceeds(
      setDoc(doc(asPatient(), 'invoices/commission'), {
        uid: CLINICIAN,
        createdBy: PATIENT,
        type: 'commission',
        amountCents: 320,
        status: 'due',
        relatedId: APPT,
      }),
    );
  });

  it('allow your own invoice', async () => {
    await assertSucceeds(
      setDoc(doc(asPatient(), 'invoices/mine'), {
        uid: PATIENT,
        type: 'subscription',
        amountCents: 1200,
        status: 'due',
      }),
    );
  });
});

describe('platform config', () => {
  it('cannot be bootstrapped by the client', async () => {
    await assertFails(
      setDoc(doc(asStranger(), 'platformConfig/settings'), {
        adminUids: [STRANGER],
        moderatorUids: [],
      }),
    );
  });
});

describe('barrier alerts', () => {
  it('cannot be resolved by an unrelated user', async () => {
    await assertFails(
      updateDoc(doc(asStranger(), 'barrierAlerts/alert-1'), { status: 'resolved' }),
    );
  });

  it('can be resolved by the reporter', async () => {
    await assertSucceeds(
      updateDoc(doc(asPatient(), 'barrierAlerts/alert-1'), { status: 'resolved' }),
    );
  });

  it('cannot be rewritten under cover of a status change', async () => {
    await assertFails(
      updateDoc(doc(asPatient(), 'barrierAlerts/alert-1'), {
        status: 'open',
        title: 'nothing to see here',
      }),
    );
  });
});

describe('session chats', () => {
  it('are unreadable by non-members', async () => {
    await assertFails(
      getDoc(doc(asStranger(), 'sessionChats/session-appt-1/messages/m1')),
    );
  });

  it('are readable by a member', async () => {
    await assertSucceeds(
      getDoc(doc(asPatient(), 'sessionChats/session-appt-1/messages/m1')),
    );
  });

  it('reject messages from non-members', async () => {
    await assertFails(
      setDoc(doc(asStranger(), 'sessionChats/session-appt-1/messages/m2'), {
        uid: STRANGER,
        body: 'let me in',
      }),
    );
  });

  it('let a visit clinician add themselves without dropping the patient', async () => {
    await assertSucceeds(
      updateDoc(doc(asClinician(), 'sessionChats/session-appt-1'), {
        participants: [PATIENT, CLINICIAN],
      }),
    );
  });

  it('refuse a stranger joining the thread', async () => {
    await assertFails(
      updateDoc(doc(asStranger(), 'sessionChats/session-appt-1'), {
        participants: [PATIENT, STRANGER],
      }),
    );
  });

  it('refuse dropping existing participants', async () => {
    await assertFails(
      updateDoc(doc(asClinician(), 'sessionChats/session-appt-1'), {
        participants: [CLINICIAN],
      }),
    );
  });

  it('let a user open their own thread', async () => {
    await assertSucceeds(
      setDoc(doc(asPatient(), 'sessionChats/telehealth-inbox-patient-1'), {
        participants: [PATIENT],
        appointmentId: '',
      }),
    );
  });
});

describe('catalog creates', () => {
  it('refuse a random place', async () => {
    await assertFails(
      setDoc(doc(asPatient(), 'places/fake-hospital'), {
        name: 'Fake Hospital',
        seeded: false,
      }),
    );
  });

  it('allow a known seed place', async () => {
    await assertSucceeds(
      setDoc(doc(asPatient(), 'places/city-hospital'), {
        name: 'City Hospital',
        seeded: true,
      }),
    );
  });

  it('allow anonymous visit-stat increments', async () => {
    await assertSucceeds(
      setDoc(doc(asPatient(), 'placeVisitStats/abb-ayub-teaching-hospital'), {
        totalVisits: 1,
        hours: { 10: 1 },
        weekday: { 1: { 10: 1 } },
      }),
    );
  });

  it('allow a signed-in user to log a search event', async () => {
    await assertSucceeds(
      setDoc(doc(asPatient(), 'searchEvents/evt-1'), {
        uid: PATIENT,
        query: 'hospital',
        category: 'hospital',
      }),
    );
  });

  it('refuse a seed place id without the seeded flag', async () => {
    await assertFails(
      setDoc(doc(asPatient(), 'places/green-cafe'), { name: 'Green Cafe' }),
    );
  });

  it('refuse a self-serve listing marked verified', async () => {
    await assertFails(
      setDoc(doc(asPatient(), 'providers/my-clinic'), {
        ownerUid: PATIENT,
        verified: true,
        name: 'My clinic',
      }),
    );
  });

  it('allow a provider to register their own unverified listing', async () => {
    await assertSucceeds(
      setDoc(doc(asPatient(), 'providers/my-clinic'), {
        ownerUid: PATIENT,
        verified: false,
        name: 'My clinic',
      }),
    );
  });

  it('refuse posting a job for an employer you do not own', async () => {
    await assertFails(
      setDoc(doc(asPatient(), 'jobs/stolen-job'), {
        employerId: 'emp-owned',
        title: 'Stolen',
      }),
    );
  });

  it('allow an employer to post a job', async () => {
    await assertSucceeds(
      setDoc(doc(asClinician(), 'jobs/posted-job'), {
        employerId: 'emp-owned',
        title: 'Inclusive engineer',
      }),
    );
  });
});
