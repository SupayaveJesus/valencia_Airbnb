import { CommonModule } from '@angular/common';
import {
  AfterViewInit,
  ChangeDetectionStrategy,
  Component,
  ElementRef,
  EventEmitter,
  Input,
  OnChanges,
  OnDestroy,
  Output,
  SimpleChanges,
  ViewChild,
} from '@angular/core';
import * as L from 'leaflet';

const DEFAULT_MAP_CENTER = L.latLng(-17.7833, -63.1821);
const DEFAULT_MAP_ZOOM = 5;
const SELECTED_MAP_ZOOM = 15;

@Component({
  selector: 'app-place-location-picker',
  standalone: true,
  templateUrl: './place-location-picker.component.html',
  styleUrl: './place-location-picker.component.scss',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [CommonModule],
})
export class PlaceLocationPickerComponent
  implements AfterViewInit, OnChanges, OnDestroy
{
  // El formulario externo controla estas coordenadas; el mapa solo las visualiza y permite cambiarlas.
  @Input() latitude: number | null = null;
  @Input() longitude: number | null = null;

  // Emitimos un objeto simple para que la página padre pueda actualizar su FormGroup sin acoplarse a Leaflet.
  @Output() readonly coordinatesChange = new EventEmitter<{
    latitude: number;
    longitude: number;
  }>();

  @ViewChild('mapCanvas') private readonly mapCanvas?: ElementRef<HTMLDivElement>;

  private map?: L.Map;
  private selectedMarker?: L.CircleMarker;

  ngAfterViewInit(): void {
    this.initializeMap();
  }

  ngOnChanges(changes: SimpleChanges): void {
    // Si las coordenadas cambian por escritura manual, reposicionamos el marcador en el mismo mapa.
    if ((changes['latitude'] || changes['longitude']) && this.map) {
      this.syncMarkerFromInputs(false);
    }
  }

  ngOnDestroy(): void {
    // Leaflet registra listeners propios; remove() libera el mapa y evita fugas al navegar entre pantallas.
    this.map?.remove();
  }

  private initializeMap(): void {
    if (!this.mapCanvas) {
      return;
    }

    const initialPoint = this.readSelectedPoint() ?? DEFAULT_MAP_CENTER;

    // scrollWheelZoom queda desactivado porque en móvil suele producir zoom accidentales al desplazarse.
    this.map = L.map(this.mapCanvas.nativeElement, {
      zoomControl: true,
      scrollWheelZoom: false,
      attributionControl: true,
    }).setView(
      initialPoint,
      this.readSelectedPoint() ? SELECTED_MAP_ZOOM : DEFAULT_MAP_ZOOM,
    );

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(this.map);

    // El gesto principal es tocar/clickear el mapa para fijar el punto exacto del lugar.
    this.map.on('click', (event: L.LeafletMouseEvent) => {
      this.applySelection(event.latlng.lat, event.latlng.lng, true);
    });

    this.syncMarkerFromInputs(false);

    // invalidateSize asegura que Leaflet calcule bien el canvas cuando Ionic termina de pintar el card.
    window.setTimeout(() => this.map?.invalidateSize(), 0);
  }

  private syncMarkerFromInputs(recenter: boolean): void {
    const selectedPoint = this.readSelectedPoint();

    if (!selectedPoint) {
      this.selectedMarker?.remove();
      this.selectedMarker = undefined;
      return;
    }

    this.applySelection(selectedPoint.lat, selectedPoint.lng, false, recenter);
  }

  private applySelection(
    latitude: number,
    longitude: number,
    emitChange: boolean,
    recenter = true,
  ): void {
    if (!this.map) {
      return;
    }

    const point = L.latLng(latitude, longitude);

    if (!this.selectedMarker) {
      // Usamos circleMarker para evitar depender de assets de íconos nativos en Android/WebView.
      this.selectedMarker = L.circleMarker(point, {
        radius: 8,
        color: '#2f6f4f',
        weight: 3,
        fillColor: '#ffffff',
        fillOpacity: 1,
      }).addTo(this.map);
    } else {
      this.selectedMarker.setLatLng(point);
    }

    if (recenter) {
      this.map.setView(point, Math.max(this.map.getZoom(), SELECTED_MAP_ZOOM));
    }

    if (emitChange) {
      // Redondeamos a 6 decimales porque es suficiente para una ubicación precisa y mantiene el campo legible.
      this.coordinatesChange.emit({
        latitude: Number(latitude.toFixed(6)),
        longitude: Number(longitude.toFixed(6)),
      });
    }
  }

  private readSelectedPoint(): L.LatLng | null {
    if (
      !Number.isFinite(this.latitude) ||
      !Number.isFinite(this.longitude) ||
      this.latitude === null ||
      this.longitude === null
    ) {
      return null;
    }

    return L.latLng(this.latitude, this.longitude);
  }
}
