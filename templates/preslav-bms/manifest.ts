import type { TemplateManifest } from '@template-contract/manifest';

const manifest: TemplateManifest = {
    id: 'preslav-bms',
    manifestVersion: 1,
    overridesSchemaVersion: 1,

    requiredHostComposables: [
        'useCurrentUser',
        'useCustomization',
        'useDevices',
        'useGroups',
        'useLiveMetric',
        'useMetricHistory',
    ],

    requiredHostExports: [
        'callMethod'
    ],

    allowedOverrideKeys: [
        'title',
        'subtitle',
        'buildingName'
    ]
};

export default manifest;
