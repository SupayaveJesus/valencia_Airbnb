/// Modelo simple del formulario de alta de lugar.
/// Lo separamos para que la misma estructura pueda reutilizarse más adelante en modo edición.
export interface LandlordPlaceDraft {
  photos: File[];
  name: string;
  description: string;
  guests: number;
  beds: number;
  bathrooms: number;
  rooms: number;
  hasWifi: boolean;
  parkingSlots: number;
  pricePerNight: number;
  cleaningCost: number;
  city: string;
  latitude: number;
  longitude: number;
}
