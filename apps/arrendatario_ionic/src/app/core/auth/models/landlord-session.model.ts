export interface LandlordSessionJson {
  id: number;
  email: string;
  fullName: string;
  phone: string;
  token: string;
  rawData: Record<string, unknown>;
}

export class LandlordSession {
  constructor(
    readonly id: number,
    readonly email: string,
    readonly fullName: string,
    readonly phone: string,
    readonly token: string,
    readonly rawData: Record<string, unknown>,
  ) {}

  get displayName(): string {
    return this.fullName || this.email || 'Arrendatario';
  }

  get hasIdentity(): boolean {
    return this.id > 0 || this.email.length > 0;
  }

  toJson(): LandlordSessionJson {
    return {
      id: this.id,
      email: this.email,
      fullName: this.fullName,
      phone: this.phone,
      token: this.token,
      rawData: this.rawData,
    };
  }

  static fromStorage(raw: string): LandlordSession | null {
    try {
      const parsed = JSON.parse(raw) as Partial<LandlordSessionJson>;
      return new LandlordSession(
        LandlordSession.readInt(parsed.id),
        LandlordSession.readString(parsed.email),
        LandlordSession.readString(parsed.fullName),
        LandlordSession.readString(parsed.phone),
        LandlordSession.readString(parsed.token),
        LandlordSession.readMap(parsed.rawData),
      );
    } catch {
      return null;
    }
  }

  static fromApi(raw: unknown): LandlordSession {
    const json = LandlordSession.readMap(raw);
    const profile = LandlordSession.extractNestedProfile(json);

    return new LandlordSession(
      LandlordSession.readInt(profile['id'] ?? json['id'] ?? json['arrendatario_id']),
      LandlordSession.readString(profile['email'] ?? json['email']),
      LandlordSession.readString(
        profile['nombrecompleto'] ??
          profile['nombre'] ??
          profile['name'] ??
          json['nombrecompleto'] ??
          json['nombre'],
      ),
      LandlordSession.readString(
        profile['telefono'] ?? profile['phone'] ?? json['telefono'] ?? json['phone'],
      ),
      LandlordSession.readString(
        json['token'] ??
          json['access_token'] ??
          json['plainTextToken'] ??
          json['bearer_token'],
      ),
      json,
    );
  }

  private static extractNestedProfile(
    json: Record<string, unknown>,
  ): Record<string, unknown> {
    const candidates = ['arrendatario', 'user', 'usuario', 'data'];

    for (const key of candidates) {
      const mapped = LandlordSession.readMap(json[key]);
      if (Object.keys(mapped).length > 0) {
        return mapped;
      }
    }

    return json;
  }

  private static readMap(value: unknown): Record<string, unknown> {
    if (value && typeof value === 'object' && !Array.isArray(value)) {
      return value as Record<string, unknown>;
    }

    return {};
  }

  private static readInt(value: unknown): number {
    if (typeof value === 'number') {
      return Number.isFinite(value) ? value : 0;
    }

    return Number.parseInt(`${value ?? ''}`, 10) || 0;
  }

  private static readString(value: unknown): string {
    return value == null ? '' : `${value}`.trim();
  }
}
