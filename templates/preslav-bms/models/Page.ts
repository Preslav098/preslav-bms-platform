export const PAGE_IDS = [
    'overview',
    'building',
    'floors',
    'devices',
    'energy',
    'climate',
    'events'
] as const;

export type PageId = typeof PAGE_IDS[number];
