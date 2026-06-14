import { signal, WritableSignal } from '@angular/core';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';

import { LandlordSession } from '../../core/auth/models/landlord-session.model';
import { AuthSessionService } from '../../core/auth/services/auth-session.service';
import { InternalShellPage } from './internal-shell.page';

describe('InternalShellPage', () => {
  let authSession: {
    clearSession: jasmine.Spy<() => Promise<void>>;
    session: WritableSignal<LandlordSession | null>;
  };
  let router: jasmine.SpyObj<Router>;

  beforeEach(async () => {
    authSession = {
      clearSession: jasmine.createSpy('clearSession').and.resolveTo(),
      session: signal(new LandlordSession(12, 'ana@test.com', 'Ana', '70000001', 'token', {})),
    };

    router = jasmine.createSpyObj<Router>('Router', ['navigateByUrl']);
    router.navigateByUrl.and.resolveTo(true);

    await TestBed.configureTestingModule({
      imports: [InternalShellPage],
      providers: [
        { provide: AuthSessionService, useValue: authSession },
        { provide: Router, useValue: router },
      ],
    }).compileComponents();
  });

  it('muestra un encabezado con saludo, navegación principal y salida visible', () => {
    const fixture = TestBed.createComponent(InternalShellPage);
    fixture.detectChanges();

    const text = fixture.nativeElement.textContent as string;

    expect(text).toContain('Valencia Airbnb');
    expect(text).toContain('Panel arrendatario');
    expect(text).toContain('Mis lugares');
    expect(text).toContain('Hola, Ana');
    expect(text).toContain('Listado');
    expect(text).toContain('Nuevo lugar');
    expect(text).toContain('Salir');
  });
});
