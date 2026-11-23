import { FormEvent, useState } from 'react';
import { api } from '../api';

interface Fields {
  name: string;
  email: string;
  message: string;
}

const empty: Fields = { name: '', email: '', message: '' };

export function ContactPage() {
  const [fields, setFields] = useState<Fields>(empty);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);
  const [sending, setSending] = useState(false);

  const update = (key: keyof Fields, value: string) => {
    setFields((current) => ({ ...current, [key]: value }));
    setError('');
    setSuccess(false);
  };

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setSending(true);
    setError('');
    setSuccess(false);
    try {
      await api.contact(fields);
      setSuccess(true);
      setFields(empty);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setSending(false);
    }
  };

  return (
    <section className="contact" data-testid="contact-page">
      <p className="eyebrow">Contacto</p>
      <h1 data-testid="contact-title">Cuéntanos tu idea</h1>
      <p className="lead">Respondemos en menos de 48 horas. Sin compromisos.</p>

      <form className="contact-form" onSubmit={submit} noValidate data-testid="contact-form">
        <label htmlFor="name">Nombre</label>
        <input
          id="name"
          data-testid="contact-name"
          value={fields.name}
          onChange={(e) => update('name', e.target.value)}
          placeholder="Tu nombre"
        />

        <label htmlFor="email">Correo electrónico</label>
        <input
          id="email"
          type="email"
          data-testid="contact-email"
          value={fields.email}
          onChange={(e) => update('email', e.target.value)}
          placeholder="tu@ejemplo.com"
        />

        <label htmlFor="message">Mensaje</label>
        <textarea
          id="message"
          data-testid="contact-message"
          value={fields.message}
          onChange={(e) => update('message', e.target.value)}
          placeholder="Describe brevemente tu proyecto"
          rows={5}
        />

        <button className="button primary" type="submit" disabled={sending} data-testid="contact-submit">
          {sending ? 'Enviando…' : 'Enviar mensaje'}
        </button>

        {error && <p className="error" data-testid="contact-error">{error}</p>}
        {success && (
          <p className="success" data-testid="contact-success">
            ¡Mensaje recibido! Te contactaremos pronto.
          </p>
        )}
      </form>
    </section>
  );
}
