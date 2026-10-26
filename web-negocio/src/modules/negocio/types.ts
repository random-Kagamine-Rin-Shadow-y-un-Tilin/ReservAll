export interface Professional {
  id_profesional: number;
  negocio_id: number;
  nombre: string;
  especialidad: string | null;
  activo: boolean;
  fecha_creacion?: string;
}

export interface ProfessionalPayload {
  nombre: string;
  especialidad: string | null;
}

export type ProfessionalEditPayload = Partial<ProfessionalPayload & { activo: boolean }>;

export interface Service {
  id_servicio: number;
  negocio_id: number;
  nombre: string;
  descripcion: string | null;
  duracion_minutos: number;
  precio: number;
  categoria_servicio: string | null;
  cantidad_servicio: number;
  estado_servicio: boolean;
  fecha_creacion?: string;
  fecha_actualizacion?: string;
  profesionales: Professional[];
}

export interface ServicePayload {
  nombre: string;
  descripcion: string | null;
  duracion_minutos: number;
  precio: number;
  categoria_servicio: string;
  cantidad_servicio: number;
  estado_servicio: boolean;
  profesional_ids: number[];
}

export type ServiceEditPayload = Partial<ServicePayload>;

export interface Schedule {
  id_horario: number;
  dia: string;
  hora_apertura: string;
  hora_cierre: string;
  hora_descanso: string | null;
  estado_horario?: boolean | null;
}

export interface SchedulePayload {
  dia: string;
  hora_apertura: string;
  hora_cierre: string;
  hora_descanso?: string | null;
}

export type ScheduleEditPayload = Omit<SchedulePayload, "dia"> & {
  estado_horario?: boolean;
};

export interface ApiMessage {
  message: string;
}
