import { fakeAsync, flushMicrotasks, TestBed } from '@angular/core/testing';

import { PreferencesStorageService } from '../../storage/preferences-storage.service';
import { AuthSessionService } from './auth-session.service';
import { LandlordSession } from '../models/landlord-session.model';

describe('AuthSessionService', () => {
  let service: AuthSessionService;
  let storage: jasmine.SpyObj<PreferencesStorageService>;

  beforeEach(() => {
    storage = jasmine.createSpyObj<PreferencesStorageService>('PreferencesStorageService', [
      'get',
      'set',
      'remove',
    ]);

    TestBed.configureTestingModule({
      providers: [{ provide: PreferencesStorageService, useValue: storage }],
    });

    service = TestBed.inject(AuthSessionService);
  });

  it('restores a valid persisted session', fakeAsync(() => {
    storage.get.and.resolveTo(
      JSON.stringify(
        new LandlordSession(3, 'demo@mail.com', 'Demo', '70000000', 'token', {}).toJson(),
      ),
    );

    void service.ensureRestored();
    flushMicrotasks();

    expect(service.isAuthenticated()).toBeTrue();
    expect(service.session()?.id).toBe(3);
  }));

  it('clears invalid persisted payloads without crashing', fakeAsync(() => {
    storage.get.and.resolveTo('{invalid-json');

    void service.ensureRestored();
    flushMicrotasks();

    expect(service.isAuthenticated()).toBeFalse();
    expect(service.session()).toBeNull();
  }));
});
