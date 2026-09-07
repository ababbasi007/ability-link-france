import type { SVGProps } from 'react'

type IconProps = SVGProps<SVGSVGElement>

function base(props: IconProps) {
  return {
    width: 18,
    height: 18,
    viewBox: '0 0 24 24',
    fill: 'none',
    stroke: 'currentColor',
    strokeWidth: 1.75,
    strokeLinecap: 'round' as const,
    strokeLinejoin: 'round' as const,
    ...props,
  }
}

export function IconGrid(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="3" y="3" width="7" height="7" rx="1.5" />
      <rect x="14" y="3" width="7" height="7" rx="1.5" />
      <rect x="3" y="14" width="7" height="7" rx="1.5" />
      <rect x="14" y="14" width="7" height="7" rx="1.5" />
    </svg>
  )
}

export function IconLayers(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M12 3l9 5-9 5-9-5 9-5z" />
      <path d="M3 12l9 5 9-5" />
      <path d="M3 16l9 5 9-5" />
    </svg>
  )
}

export function IconHeart(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M12 20s-7-4.4-7-9.2A3.8 3.8 0 0 1 12 7.5a3.8 3.8 0 0 1 7 3.3C19 15.6 12 20 12 20z" />
    </svg>
  )
}

export function IconGraduation(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M3 10l9-5 9 5-9 5-9-5z" />
      <path d="M7 12.5v4.2c0 .8 2.2 2.3 5 2.3s5-1.5 5-2.3v-4.2" />
      <path d="M21 10v6" />
    </svg>
  )
}

export function IconBriefcase(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="3" y="8" width="18" height="12" rx="2" />
      <path d="M9 8V6a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2M3 13h18" />
    </svg>
  )
}

export function IconMapPin(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M12 21s7-4.5 7-11a7 7 0 1 0-14 0c0 6.5 7 11 7 11z" />
      <circle cx="12" cy="10" r="2.5" />
    </svg>
  )
}

export function IconPlusCircle(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 8v8M8 12h8" />
    </svg>
  )
}

export function IconPause(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="7" y="6" width="3.5" height="12" rx="1" />
      <rect x="13.5" y="6" width="3.5" height="12" rx="1" />
    </svg>
  )
}

export function IconShieldCheck(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M12 3l7 3v5c0 4.5-3 7.5-7 9-4-1.5-7-4.5-7-9V6l7-3z" />
      <path d="M9 12l2 2 4-4" />
    </svg>
  )
}

export function IconFlag(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M5 21V4" />
      <path d="M5 4h10l-1.5 3.5L15 11H5" />
    </svg>
  )
}

export function IconStar(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M12 3l2.4 4.9 5.4.8-3.9 3.8.9 5.4L12 15.9 7.2 18l.9-5.4L4.2 8.7l5.4-.8L12 3z" />
    </svg>
  )
}

export function IconUsers(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="9" cy="8" r="3" />
      <path d="M3 19c0-3 2.5-5 6-5s6 2 6 5" />
      <circle cx="17" cy="9" r="2.5" />
      <path d="M16 19c0-2 1.2-3.5 3.5-4" />
    </svg>
  )
}

export function IconUser(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="8" r="3.5" />
      <path d="M5 19c1.5-3.2 4-4.8 7-4.8S17.5 15.8 19 19" />
    </svg>
  )
}

export function IconTrendUp(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 16l6-6 4 4 6-7" />
      <path d="M15 7h5v5" />
    </svg>
  )
}

export function IconTrendDown(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 8l6 6 4-4 6 7" />
      <path d="M15 17h5v-5" />
    </svg>
  )
}

export function IconTags(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M3 12V5a2 2 0 0 1 2-2h7l9 9-9 9-9-9z" />
      <circle cx="8.5" cy="8.5" r="1.2" fill="currentColor" stroke="none" />
    </svg>
  )
}

export function IconAccessibility(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="5" r="2" />
      <path d="M7 10h10M12 7v5l4 6M12 12l-4 6" />
    </svg>
  )
}

export function IconChart(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 19V5M4 19h16" />
      <path d="M8 16V10M12 16V7M16 16v-5" />
    </svg>
  )
}

export function IconBell(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M6 16h12l-1.2-2.2a6 6 0 0 1-.8-3V9a4 4 0 1 0-8 0v1.8a6 6 0 0 1-.8 3L6 16z" />
      <path d="M10 18a2 2 0 0 0 4 0" />
    </svg>
  )
}

export function IconSend(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 12l16-8-6 18-2.5-7.5L4 12z" />
      <path d="M14 10l-2.5 4.5" />
    </svg>
  )
}

export function IconXCircle(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="12" r="9" />
      <path d="M9 9l6 6M15 9l-6 6" />
    </svg>
  )
}

export function IconRefresh(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 12a8 8 0 0 1 14-5.3M20 12a8 8 0 0 1-14 5.3" />
      <path d="M18 3v5h-5M6 21v-5h5" />
    </svg>
  )
}

export function IconMegaphone(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 10v4l12 3V7L4 10z" />
      <path d="M16 9.5v5a3.5 3.5 0 0 0 3.5-3.5A3.5 3.5 0 0 0 16 9.5z" />
      <path d="M7 14v3.5a2 2 0 0 0 2.5 1.9L11 19" />
    </svg>
  )
}

export function IconSettings(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="12" r="3" />
      <path d="M12 3v2M12 19v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M3 12h2M19 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
    </svg>
  )
}

export function IconLock(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="5" y="11" width="14" height="10" rx="2" />
      <path d="M8 11V8a4 4 0 0 1 8 0v3" />
    </svg>
  )
}

export function IconCreditCard(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="3" y="6" width="18" height="13" rx="2" />
      <path d="M3 10h18M7 15h4" />
    </svg>
  )
}

export function IconSliders(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 7h10M18 7h2M4 17h2M10 17h10" />
      <circle cx="16" cy="7" r="2" />
      <circle cx="8" cy="17" r="2" />
    </svg>
  )
}

export function IconCloud(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M8 18h9a4 4 0 0 0 .5-8 5.5 5.5 0 0 0-10.5 1.5A3.5 3.5 0 0 0 8 18z" />
    </svg>
  )
}

export function IconCode(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M9 7L4 12l5 5M15 7l5 5-5 5" />
    </svg>
  )
}

export function IconAdmins(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="8" r="3.5" />
      <path d="M5 19c1.5-3 4-4.5 7-4.5S17.5 16 19 19" />
      <path d="M16 5.5l1.2.4.4 1.2-.4 1.2-1.2.4-1.2-.4-.4-1.2.4-1.2L16 5.5z" />
    </svg>
  )
}

export function IconLogs(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M8 6h12M8 12h12M8 18h12" />
      <circle cx="4" cy="6" r="1" fill="currentColor" stroke="none" />
      <circle cx="4" cy="12" r="1" fill="currentColor" stroke="none" />
      <circle cx="4" cy="18" r="1" fill="currentColor" stroke="none" />
    </svg>
  )
}

export function IconMenu(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 7h16M4 12h16M4 17h16" />
    </svg>
  )
}

export function IconSearch(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="11" cy="11" r="6.5" />
      <path d="M16.5 16.5L21 21" />
    </svg>
  )
}

export function IconCalendar(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="3.5" y="5" width="17" height="15" rx="2" />
      <path d="M8 3v4M16 3v4M3.5 10h17" />
    </svg>
  )
}

export function IconClock(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="12" r="8" />
      <path d="M12 8v5l3 2" />
    </svg>
  )
}

export function IconChevronDown(p: IconProps) {
  return (
    <svg {...base({ width: 14, height: 14, ...p })}>
      <path d="M6 9l6 6 6-6" />
    </svg>
  )
}

export function IconWheelchair(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="10" cy="5" r="2" />
      <path d="M12 8l2 4h4" />
      <circle cx="9" cy="16" r="4" />
      <path d="M13 12l2 7" />
    </svg>
  )
}

export function IconRestroom(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="5" r="2" />
      <path d="M9 9h6l-1 10h-4L9 9z" />
    </svg>
  )
}

export function IconRamp(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 18h16M5 18V8l14 10" />
    </svg>
  )
}

export function IconElevator(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="5" y="3" width="14" height="18" rx="2" />
      <path d="M12 8l3 3H9l3-3zM12 16l-3-3h6l-3 3z" />
    </svg>
  )
}

export function IconParking(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="4" y="3" width="16" height="18" rx="2" />
      <path d="M9 17V7h4a3 3 0 0 1 0 6H9" />
    </svg>
  )
}

export function IconPlus(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M12 5v14M5 12h14" />
    </svg>
  )
}

export function IconDownload(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M12 4v10M8 10l4 4 4-4M5 19h14" />
    </svg>
  )
}

export function IconFilter(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 5h16l-6 7v5l-4 2v-7L4 5z" />
    </svg>
  )
}

export function IconEye(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  )
}

export function IconPencil(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 20h4l10-10-4-4L4 16v4z" />
      <path d="M12 6l4 4" />
    </svg>
  )
}

export function IconMore(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="6" cy="12" r="1.4" fill="currentColor" stroke="none" />
      <circle cx="12" cy="12" r="1.4" fill="currentColor" stroke="none" />
      <circle cx="18" cy="12" r="1.4" fill="currentColor" stroke="none" />
    </svg>
  )
}

export function IconBuilding(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="5" y="3" width="14" height="18" rx="1.5" />
      <path d="M9 7h2M13 7h2M9 11h2M13 11h2M9 15h2M13 15h2M10 21v-3h4v3" />
    </svg>
  )
}

export function IconStarFill(p: IconProps) {
  return (
    <svg {...base({ ...p, fill: 'currentColor', stroke: 'none' })}>
      <path d="M12 3l2.4 4.9 5.4.8-3.9 3.8.9 5.4L12 15.9 7.2 18l.9-5.4L4.2 8.7l5.4-.8L12 3z" />
    </svg>
  )
}

export function IconCheckCircle(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="12" r="8" />
      <path d="M8.5 12.5l2.2 2.2 4.8-5" />
    </svg>
  )
}

export function IconChevronLeft(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M15 6l-6 6 6 6" />
    </svg>
  )
}

export function IconChevronRight(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M9 6l6 6-6 6" />
    </svg>
  )
}

export function IconX(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M6 6l12 12M18 6L6 18" />
    </svg>
  )
}

export function IconPhone(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M7 3h3l1.5 4-2 1.5a12 12 0 0 0 5 5L16 12l4 1.5V16a2 2 0 0 1-2 2A13 13 0 0 1 5 5a2 2 0 0 1 2-2z" />
    </svg>
  )
}

export function IconCopy(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="8" y="8" width="11" height="11" rx="2" />
      <path d="M5 14V6a2 2 0 0 1 2-2h8" />
    </svg>
  )
}

export function IconExternalLink(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M14 5h5v5M19 5l-9 9M10 5H6a2 2 0 0 0-2 2v11a2 2 0 0 0 2 2h11a2 2 0 0 0 2-2v-4" />
    </svg>
  )
}

export function IconHeadset(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 13v-2a8 8 0 0 1 16 0v2" />
      <path d="M4 13a2 2 0 0 0 2 2h1v-5H6a2 2 0 0 0-2 2zM20 13a2 2 0 0 1-2 2h-1v-5h1a2 2 0 0 1 2 2z" />
      <path d="M16 18a4 4 0 0 1-8 0" />
    </svg>
  )
}

export function IconInfo(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="12" r="9" />
      <path d="M12 10v6M12 7h.01" />
    </svg>
  )
}

export function IconWarning(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M12 4l9 16H3L12 4z" />
      <path d="M12 10v4M12 16.5h.01" />
    </svg>
  )
}

export function IconTrash(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 7h16M9 7V5h6v2M8 7l1 13h6l1-13" />
    </svg>
  )
}

export function IconFileText(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M7 3h7l5 5v13H7V3z" />
      <path d="M14 3v5h5M10 12h6M10 16h6" />
    </svg>
  )
}

export function IconDatabase(p: IconProps) {
  return (
    <svg {...base(p)}>
      <ellipse cx="12" cy="6" rx="7" ry="3" />
      <path d="M5 6v6c0 1.7 3.1 3 7 3s7-1.3 7-3V6M5 12v6c0 1.7 3.1 3 7 3s7-1.3 7-3v-6" />
    </svg>
  )
}

export function IconCheck(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M5 12l5 5L20 7" />
    </svg>
  )
}

export function IconBan(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="12" r="9" />
      <path d="M7 7l10 10" />
    </svg>
  )
}

export function IconMessage(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M5 6h14a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H9l-4 3V8a2 2 0 0 1 2-2z" />
    </svg>
  )
}

export function IconMoreVertical(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="6" r="1.4" fill="currentColor" stroke="none" />
      <circle cx="12" cy="12" r="1.4" fill="currentColor" stroke="none" />
      <circle cx="12" cy="18" r="1.4" fill="currentColor" stroke="none" />
    </svg>
  )
}

export function IconChevronsLeft(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M11 6l-6 6 6 6M18 6l-6 6 6 6" />
    </svg>
  )
}

export function IconChevronsRight(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M13 6l6 6-6 6M6 6l6 6-6 6" />
    </svg>
  )
}

export function IconUtensils(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M8 4v7a2 2 0 0 0 2 2h0a2 2 0 0 0 2-2V4M10 13v7M16 4v16M16 4c2 2 2 5 0 7" />
    </svg>
  )
}

export function IconShoppingBag(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M6 8h12l-1 12H7L6 8z" />
      <path d="M9 8V6a3 3 0 0 1 6 0v2" />
    </svg>
  )
}

export function IconTree(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M12 21v-6" />
      <path d="M7 15c0-4 2.5-7 5-9 2.5 2 5 5 5 9H7z" />
      <path d="M9 11c0-2.5 1.5-4.5 3-5.5 1.5 1 3 3 3 5.5" />
    </svg>
  )
}

export function IconTrain(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="6" y="4" width="12" height="13" rx="2" />
      <path d="M6 11h12M9 17l-2 3M15 17l2 3M10 7h4" />
    </svg>
  )
}

export function IconCross(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M12 7v10M7 12h10" strokeWidth={2.25} />
    </svg>
  )
}

export function IconSave(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M5 4h11l3 3v13H5V4z" />
      <path d="M8 4v5h7V4M8 20v-7h8v7" />
    </svg>
  )
}

export function IconGlobe(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="12" cy="12" r="9" />
      <path d="M3 12h18M12 3c3 3.5 3 14.5 0 18M12 3c-3 3.5-3 14.5 0 18" />
    </svg>
  )
}

export function IconTruck(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M1 7h13v9H1z" />
      <path d="M14 10h4l3 3v3h-7v-6z" />
      <circle cx="5.5" cy="17.5" r="1.5" />
      <circle cx="16.5" cy="17.5" r="1.5" />
    </svg>
  )
}

export function IconMail(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="3" y="5" width="18" height="14" rx="2" />
      <path d="M3 7l9 7 9-7" />
    </svg>
  )
}

export function IconUpload(p: IconProps) {
  return (
    <svg {...base({ width: 28, height: 28, ...p })}>
      <path d="M12 16V7M8.5 10.5L12 7l3.5 3.5" />
      <path d="M5 16v3a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2v-3" />
    </svg>
  )
}

export function IconDoor(p: IconProps) {
  return (
    <svg {...base(p)}>
      <rect x="6" y="3" width="12" height="18" rx="1" />
      <circle cx="14" cy="12" r="1" fill="currentColor" stroke="none" />
    </svg>
  )
}

export function IconEar(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M8 12c0-3 2-5 4.5-5S17 9 17 12c0 2-1 3-2.5 3.5" />
      <path d="M10 18c1 1 2 1.5 3.5 1.5 2.5 0 4.5-2 4.5-5" />
    </svg>
  )
}

export function IconEyeOpen(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" />
      <circle cx="12" cy="12" r="3" />
    </svg>
  )
}

export function IconPaw(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="8" cy="9" r="2" />
      <circle cx="16" cy="9" r="2" />
      <circle cx="6" cy="14" r="1.6" />
      <circle cx="18" cy="14" r="1.6" />
      <path d="M9 18c1.5-2 4.5-2 6 0" />
    </svg>
  )
}

export function IconPath(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M5 19l6-6 3 3 5-7" />
      <circle cx="19" cy="7" r="2" />
    </svg>
  )
}

export function IconBraille(p: IconProps) {
  return (
    <svg {...base(p)}>
      <circle cx="8" cy="8" r="1.4" fill="currentColor" stroke="none" />
      <circle cx="16" cy="8" r="1.4" fill="currentColor" stroke="none" />
      <circle cx="8" cy="16" r="1.4" fill="currentColor" stroke="none" />
      <circle cx="16" cy="16" r="1.4" fill="currentColor" stroke="none" />
    </svg>
  )
}

export function IconAudio(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 10v4h3l4 3V7L7 10H4z" />
      <path d="M15 9a4 4 0 0 1 0 6M17.5 7a7 7 0 0 1 0 10" />
    </svg>
  )
}

export function IconTactile(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M4 18h16M6 18V8l4 4 4-6 4 8" />
    </svg>
  )
}

export function IconBrain(p: IconProps) {
  return (
    <svg {...base(p)}>
      <path d="M9 4a3 3 0 0 0-3 3v1a2.5 2.5 0 0 0-1 4.8V15a3 3 0 0 0 3 3h1" />
      <path d="M15 4a3 3 0 0 1 3 3v1a2.5 2.5 0 0 1 1 4.8V15a3 3 0 0 1-3 3h-1" />
      <path d="M12 4v16M9 10h6M9 14h6" />
    </svg>
  )
}
