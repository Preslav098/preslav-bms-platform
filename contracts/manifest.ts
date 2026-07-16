export interface TemplateManifest {
    id: string;
    manifestVersion: number;
    overridesSchemaVersion: number;
    requiredHostExports?: string[];
    requiredHostComposables?: string[];
    allowedOverrideKeys?: string[];
}
