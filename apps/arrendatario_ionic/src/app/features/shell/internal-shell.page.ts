import { CommonModule } from '@angular/common';
import { Component, computed, inject } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';
import {
  IonButton,
  IonContent,
  IonHeader,
  IonTitle,
  IonToolbar,
} from '@ionic/angular/standalone';

import { AuthSessionService } from '../../core/auth/services/auth-session.service';

/**
 * El shell interno contiene el marco estable de la app autenticada: cabecera,
 * navegación principal y logout. Las páginas hijas solo resuelven su caso de uso.
 */
@Component({
  selector: 'app-internal-shell-page',
  standalone: true,
  templateUrl: './internal-shell.page.html',
  styleUrl: './internal-shell.page.scss',
  imports: [
    CommonModule,
    RouterLink,
    RouterLinkActive,
    RouterOutlet,
    IonButton,
    IonContent,
    IonHeader,
    IonTitle,
    IonToolbar,
  ],
})
export class InternalShellPage {
  private readonly authSession = inject(AuthSessionService);
  private readonly router = inject(Router);

  // El shell lee la sesión para mostrar contexto de quién está dentro de la app.
  readonly session = this.authSession.session;
  // computed mantiene el saludo sincronizado con cambios de sesión sin lógica manual extra.
  readonly welcomeMessage = computed(
    () => `Hola, ${this.session()?.displayName ?? 'arrendatario'}`,
  );

  async logout(): Promise<void> {
    // Primero cerramos sesión local/persistida, después navegamos al flujo público.
    await this.authSession.clearSession();
    // replaceUrl evita que el usuario vuelva con "atrás" a una pantalla protegida vieja.
    await this.router.navigateByUrl('/login', { replaceUrl: true });
  }
}
