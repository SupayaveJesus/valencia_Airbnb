import { CommonModule } from '@angular/common';
import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import {
  IonButton,
  IonCard,
  IonCardContent,
  IonContent,
  IonInput,
  IonItem,
  IonNote,
  IonText,
} from '@ionic/angular/standalone';

import { AuthSessionService } from '../../core/auth/services/auth-session.service';
import {
  LandlordAuthApiService,
  LandlordAuthIdentityError,
} from '../../core/auth/services/landlord-auth-api.service';
import { ApiRequestError } from '../../core/http/api-client.service';

type LoginErrorTone = 'network' | 'auth' | 'server';

/**
 * Pantalla de acceso con diagnóstico legible para pruebas web y mobile.
 * La vista captura credenciales, pero delega autenticación real a servicios de core.
 */
@Component({
  selector: 'app-login-page',
  standalone: true,
  templateUrl: './login.page.html',
  styleUrl: './login.page.scss',
  imports: [
    CommonModule,
    ReactiveFormsModule,
    RouterLink,
    IonButton,
    IonCard,
    IonCardContent,
    IonContent,
    IonInput,
    IonItem,
    IonNote,
    IonText,
  ],
})
export class LoginPage {
  private readonly formBuilder = inject(FormBuilder);
  private readonly authApi = inject(LandlordAuthApiService);
  private readonly authSession = inject(AuthSessionService);
  private readonly router = inject(Router);

  // Signals para estado visual inmediato del formulario.
  readonly loading = signal(false);
  readonly errorMessage = signal('');
  readonly errorDetail = signal('');
  readonly errorTone = signal<LoginErrorTone>('server');
  // Si registro redirige al login con un mensaje, lo mostramos como contexto inicial.
  readonly noticeMessage = signal(
    this.readNavigationMessage() || 'Ingresá con tu cuenta de arrendatario.',
  );

  // FormGroup tipado: valida temprano y evita mandar basura al backend.
  readonly form = this.formBuilder.nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(4)]],
  });

  async submit(): Promise<void> {
    // Si el formulario no cumple reglas mínimas, frenamos antes de tocar la red.
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    // Limpiamos errores previos para que el usuario vea el resultado del intento actual.
    this.loading.set(true);
    this.errorMessage.set('');
    this.errorDetail.set('');

    try {
      // Leemos valores crudos del form y los enviamos al servicio de autenticación.
      const session = await this.authApi.login(
        this.form.controls.email.getRawValue(),
        this.form.controls.password.getRawValue(),
      );

      // Si el login fue exitoso, abrimos sesión centralizada y vamos al área interna.
      await this.authSession.openSession(session);
      await this.router.navigateByUrl('/app/lugares', { replaceUrl: true });
    } catch (error) {
      // Toda traducción de error hacia la UI queda concentrada en un método específico.
      this.applyLoginError(error);
    } finally {
      this.loading.set(false);
    }
  }

  private applyLoginError(error: unknown): void {
    if (error instanceof ApiRequestError) {
      // Error de infraestructura/API conocida: separamos tono, mensaje corto y detalle técnico.
      this.errorTone.set(error.kind);
      this.errorMessage.set(this.resolveApiMessage(error));
      this.errorDetail.set(this.formatAttempts(error.attempts));
      return;
    }

    if (error instanceof LandlordAuthIdentityError) {
      // El backend respondió, pero no con datos suficientes para construir sesión confiable.
      this.errorTone.set('server');
      this.errorMessage.set(error.message);
      this.errorDetail.set(error.detail);
      return;
    }

    this.errorTone.set('server');
    this.errorMessage.set(error instanceof Error ? error.message : 'No se pudo iniciar sesión.');
    this.errorDetail.set('');
  }

  private resolveApiMessage(error: ApiRequestError): string {
    // Convertimos categorías técnicas a mensajes humanos accionables.
    if (error.kind === 'network') {
      return 'No pudimos comunicarnos con el backend. Revisá conexión, CORS o certificados y probá de nuevo.';
    }

    if (error.kind === 'auth') {
      return error.message;
    }

    return 'El backend respondió, pero el ingreso no se pudo completar con las rutas habilitadas.';
  }

  private formatAttempts(attempts: { url: string; status: number; message: string }[]): string {
    // Esto arma un log compacto para defensa técnica o debugging sin abrir DevTools.
    return attempts
      .map((attempt) => `${attempt.url} -> HTTP ${attempt.status || 0} - ${attempt.message}`)
      .join('\n');
  }

  private readNavigationMessage(): string {
    // getCurrentNavigation solo existe durante la navegación actual; por eso leemos y normalizamos acá.
    const message = this.router.getCurrentNavigation()?.extras.state?.['message'];
    return typeof message === 'string' ? message.trim() : '';
  }
}
