import { useState, type FormEvent } from 'react'
import { Link } from 'react-router-dom'
import { PageHeader, Widget } from '../components/PageChrome'
import {
  IconAccessibility,
  IconCalendar,
  IconCheck,
  IconChevronRight,
  IconClock,
  IconCreditCard,
  IconFileText,
  IconHeadset,
  IconLock,
  IconMail,
  IconMessage,
  IconPhone,
  IconSearch,
  IconSettings,
  IconShieldCheck,
  IconUser,
} from '../components/icons'

const TOPICS = [
  {
    title: 'Getting Started',
    desc: 'Learn the basics and set up your account.',
    tone: 'blue',
    icon: <IconUser width={20} height={20} />,
  },
  {
    title: 'Bookings',
    desc: 'How to book, reschedule or cancel sessions.',
    tone: 'green',
    icon: <IconCalendar width={20} height={20} />,
  },
  {
    title: 'Payments',
    desc: 'Billing, invoices and refunds.',
    tone: 'orange',
    icon: <IconCreditCard width={20} height={20} />,
  },
  {
    title: 'Tele Rehab',
    desc: 'Join sessions and troubleshooting.',
    tone: 'purple',
    icon: <IconHeadset width={20} height={20} />,
  },
  {
    title: 'Account & Settings',
    desc: 'Manage your profile and preferences.',
    tone: 'pink',
    icon: <IconSettings width={20} height={20} />,
  },
  {
    title: 'Accessibility',
    desc: 'App accessibility features and tools.',
    tone: 'blue',
    icon: <IconAccessibility width={20} height={20} />,
  },
  {
    title: 'Troubleshooting',
    desc: 'Fix common issues.',
    tone: 'green',
    icon: <IconLock width={20} height={20} />,
  },
  {
    title: 'Safety & Privacy',
    desc: 'Data, privacy and account security.',
    tone: 'red',
    icon: <IconShieldCheck width={20} height={20} />,
  },
]

const FAQS = [
  {
    q: 'How do I book a Tele Rehab session?',
    a: 'Go to Tele Rehab from the sidebar, pick a therapist, choose a time slot, and confirm. You will receive a join link before the session.',
  },
  {
    q: 'What payment methods are accepted?',
    a: 'Ability Link supports cards (Visa/Mastercard), easypaisa, JazzCash, and wallet top-ups from the Payments page.',
  },
  {
    q: 'Why is my place verification pending?',
    a: 'Place submissions are reviewed by moderators. Check Place Verification under Operations for status and any requested documents.',
  },
  {
    q: 'How do I export reports?',
    a: 'Open Reports & Analytics, apply your filters, then use Export as PDF, Excel, or CSV from the right rail.',
  },
  {
    q: 'How do I manage admin users?',
    a: 'Super Admins can invite and assign roles from the Admins page under System.',
  },
]

const VIDEOS = [
  {
    title: 'Getting Started with Ability Link',
    duration: '2:45',
    thumb: 'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=240&q=80',
  },
  {
    title: 'Booking your first appointment',
    duration: '3:12',
    thumb: 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=240&q=80',
  },
  {
    title: 'Using Assistive Technology marketplace',
    duration: '4:05',
    thumb: 'https://images.unsplash.com/photo-1576765608535-5f04d1e3f289?w=240&q=80',
  },
  {
    title: 'Accessibility settings walkthrough',
    duration: '2:18',
    thumb: 'https://images.unsplash.com/photo-1551836022-d5d32dca6fda?w=240&q=80',
  },
]

const QUICK_LINKS = [
  { label: 'User Guide', to: '/settings', icon: <IconFileText width={14} height={14} /> },
  { label: 'Community Forum', to: '/community', icon: <IconMessage width={14} height={14} /> },
  { label: 'Report a Problem', to: '/reports', icon: <IconLock width={14} height={14} /> },
  { label: 'Suggest a Feature', to: '/support', icon: <IconMail width={14} height={14} /> },
  { label: 'Terms of Service', to: '/legal-rights', icon: <IconFileText width={14} height={14} /> },
  { label: 'Privacy Policy', to: '/legal-rights', icon: <IconShieldCheck width={14} height={14} /> },
]

export function ContactSupportPage() {
  const [helpQ, setHelpQ] = useState('')
  const [openFaq, setOpenFaq] = useState<number | null>(0)
  const [subject, setSubject] = useState('')
  const [message, setMessage] = useState('')
  const [sent, setSent] = useState(false)
  const [showCompose, setShowCompose] = useState(false)

  const onSubmit = (e: FormEvent) => {
    e.preventDefault()
    setSent(true)
    setSubject('')
    setMessage('')
    setShowCompose(false)
  }

  const topics = TOPICS.filter(
    (t) =>
      !helpQ.trim() ||
      t.title.toLowerCase().includes(helpQ.trim().toLowerCase()) ||
      t.desc.toLowerCase().includes(helpQ.trim().toLowerCase()),
  )

  return (
    <div className="al-page">
      <PageHeader
        title="Help & Support"
        subtitle="We're here to help you. Find answers, get support, or contact our team."
      />

      <div className="al-split">
        <div>
          <section className="al-help-hero">
            <div className="al-help-hero-copy">
              <h2>How can we help you today?</h2>
              <p>Search our help center for guides, FAQs and support articles.</p>
              <div className="al-help-hero-search">
                <div className="al-filter-search">
                  <IconSearch width={15} height={15} />
                  <input
                    value={helpQ}
                    onChange={(e) => setHelpQ(e.target.value)}
                    placeholder="Search help articles, FAQs, or type your question..."
                  />
                </div>
                <button type="button" className="al-btn al-btn--primary">
                  Search
                </button>
              </div>
            </div>
            <div className="al-help-hero-art" aria-hidden>
              <div className="al-help-hero-agent">
                <IconHeadset width={36} height={36} />
              </div>
              <p className="al-help-hero-bubble">Together for a more inclusive tomorrow</p>
            </div>
          </section>

          <h3 className="al-help-section-title">Popular Help Topics</h3>
          <div className="al-help-topics">
            {topics.map((t) => (
              <button key={t.title} type="button" className={`al-help-topic al-help-topic--${t.tone}`}>
                <span className="al-help-topic-icon">{t.icon}</span>
                <strong>{t.title}</strong>
                <span>{t.desc}</span>
                <IconChevronRight className="al-help-topic-chevron" width={16} height={16} />
              </button>
            ))}
          </div>

          <div className="al-help-bottom">
            <section className="al-table-card al-help-faq">
              <div className="al-help-section-head">
                <strong>Frequently Asked Questions</strong>
                <button type="button" className="al-btn al-btn--ghost">
                  View All
                </button>
              </div>
              <div className="al-help-accordion">
                {FAQS.map((item, i) => (
                  <div key={item.q} className={`al-help-acc-item${openFaq === i ? ' open' : ''}`}>
                    <button
                      type="button"
                      className="al-help-acc-q"
                      onClick={() => setOpenFaq(openFaq === i ? null : i)}
                      aria-expanded={openFaq === i}
                    >
                      {item.q}
                      <IconChevronRight width={14} height={14} />
                    </button>
                    {openFaq === i ? <p className="al-help-acc-a">{item.a}</p> : null}
                  </div>
                ))}
              </div>
            </section>

            <section className="al-table-card al-help-videos">
              <div className="al-help-section-head">
                <strong>Video Guides</strong>
                <button type="button" className="al-btn al-btn--ghost">
                  View All
                </button>
              </div>
              <div className="al-help-video-list">
                {VIDEOS.map((v) => (
                  <article key={v.title} className="al-help-video-item">
                    <div className="al-help-video-thumb">
                      <img src={v.thumb} alt="" />
                      <span className="al-help-video-play" aria-hidden>
                        ▶
                      </span>
                      <span className="al-help-video-dur">{v.duration}</span>
                    </div>
                    <strong>{v.title}</strong>
                  </article>
                ))}
              </div>
            </section>
          </div>
        </div>

        <div className="al-widgets">
          <Widget title="Contact Support">
            <div className="al-help-contact">
              <span className="al-kpi-icon" style={{ background: '#dbeafe', color: '#2563eb' }}>
                <IconHeadset width={20} height={20} />
              </span>
              <p>Still need help? Our support team is ready to assist you.</p>
              {sent ? (
                <div className="al-help-sent">
                  <IconCheck width={15} height={15} /> Message queued — we will follow up by email.
                </div>
              ) : null}
              {!showCompose ? (
                <button
                  type="button"
                  className="al-btn al-btn--primary"
                  style={{ width: '100%' }}
                  onClick={() => setShowCompose(true)}
                >
                  <IconMail width={14} height={14} /> Send a Message
                </button>
              ) : (
                <form onSubmit={onSubmit} className="al-help-compose">
                  <input
                    placeholder="Subject"
                    value={subject}
                    onChange={(e) => setSubject(e.target.value)}
                    required
                  />
                  <textarea
                    placeholder="Describe your issue..."
                    rows={3}
                    value={message}
                    onChange={(e) => setMessage(e.target.value)}
                    required
                  />
                  <button type="submit" className="al-btn al-btn--primary" style={{ width: '100%' }}>
                    Send
                  </button>
                </form>
              )}
              <div className="al-help-contact-secondary">
                <button type="button" className="al-btn al-btn--outline">
                  <IconMessage width={14} height={14} /> Live Chat
                </button>
                <button type="button" className="al-btn al-btn--outline">
                  <IconPhone width={14} height={14} /> Request a Call
                </button>
              </div>
              <p className="muted" style={{ fontSize: 11, textAlign: 'center', margin: '8px 0 0' }}>
                Live chat available 9 AM – 9 PM
              </p>
            </div>
          </Widget>

          <Widget title="Support Hours">
            <div className="al-help-hours">
              <IconClock width={16} height={16} style={{ color: '#2563eb' }} />
              <div className="al-detail-kv">
                <div>
                  <span>Monday – Friday</span>
                  <strong>9:00 AM – 9:00 PM</strong>
                </div>
                <div>
                  <span>Weekends</span>
                  <strong>10:00 AM – 6:00 PM</strong>
                </div>
              </div>
            </div>
          </Widget>

          <Widget title="Quick Links">
            <div className="al-help-links">
              {QUICK_LINKS.map((l) => (
                <Link key={l.label} to={l.to} className="al-help-link">
                  <span>
                    {l.icon} {l.label}
                  </span>
                  <IconChevronRight width={14} height={14} />
                </Link>
              ))}
            </div>
          </Widget>

          <div className="al-help-feedback">
            <IconMessage width={20} height={20} />
            <strong>We value your feedback</strong>
            <p>Help us improve by sharing your suggestions or experience.</p>
            <button type="button" className="al-btn al-btn--outline">
              Give Feedback →
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
