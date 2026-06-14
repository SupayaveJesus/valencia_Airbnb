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
  IonText,
} from '@ionic/angular/standalone';

import { AuthSessionService } from '../../core/auth/services/auth-session.service';
import { LandlordAuthApiService } from '../../core/auth/services/landlord-auth-api.service';

@Component({
  selector: 'app-register-page',
  standalone: true,
  templateUrl: './register.page.html',
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
    IonText,
  ],
})
export class RegisterPage {
  private readonly formBuilder = inject(FormBuilder);
  private readonly authApi = inject(LandlordAuthApiService);
  private readonly authSession = inject(AuthSessionService);
  private readonly router = inject(Router);

  // Estado visual mínimo para feedback de envío y error.
  readonly loading = signal(false);
  readonly errorMessage = signal('');

  // El registro pide solo los datos que hoy sabemos enviar al backend real.
  readonly form = this.formBuilder.nonNullable.group({
    fullName: ['', [Validators.required, Validators.minLength(4)]],
    email: ['', [Validators.required, Validators.email]],
    phone: ['', [Validators.required, Validators.minLength(7)]],
    password: ['', [Validators.required, Validators.minLength(4)]],
  });

  async submit(): Promise<void> {
    // La validación local evita requests innecesarios y destaca campos incompletos.
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }

    this.loading.set(true);
    this.errorMessage.set('');

    try {
      // El formulario entrega un objeto simple; authApi traduce esto al contrato HTTP real.
      const result = await this.authApi.register(this.form.getRawValue());

      if (result.session) {
        // Si la API devolvió identidad usable, entramos directo sin obligar a reloguearse.
        await this.authSession.openSession(result.session);
        await this.router.navigateByUrl('/app/lugares', { replaceUrl: true });
        return;
      }

      // Si no hubo sesión, igualmente redirigimos al login con mensaje contextual.
      await this.router.navigate(['/login'], {
        replaceUrl: true,
        state: { message: result.message },
      });
    } catch (error) {
      // Fallback único y claro para cualquier fallo no recuperable del alta.
      this.errorMessage.set(error instanceof Error ? error.message : 'No se pudo crear la cuenta.');
    } finally {
      this.loading.set(false);
    }
  }
}
