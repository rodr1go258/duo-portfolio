import { Router } from 'express';
import { z } from 'zod';
import { AppError } from '../services/project.service';

const contactSchema = z.object({
  name: z.string().trim().min(2, 'El nombre debe tener al menos 2 caracteres').max(80),
  email: z.string().trim().email('Introduce un correo válido'),
  message: z.string().trim().min(10, 'El mensaje debe tener al menos 10 caracteres').max(1000)
});

export interface ContactMessage {
  id: number;
  receivedAt: string;
  name: string;
  email: string;
  message: string;
}

let sequence = 0;
const inbox: ContactMessage[] = [];

export function contactRouter(): Router {
  const router = Router();

  router.post('/', (req, res, next) => {
    const parsed = contactSchema.safeParse(req.body ?? {});
    if (!parsed.success) {
      next(
        new AppError(
          400,
          parsed.error.issues.map((issue) => issue.message).join('; ')
        )
      );
      return;
    }

    sequence += 1;
    const message: ContactMessage = {
      id: sequence,
      receivedAt: new Date().toISOString(),
      ...parsed.data
    };
    inbox.push(message);
    res.status(202).json({ ok: true, id: message.id, receivedAt: message.receivedAt });
  });

  router.get('/', (_req, res) => {
    res.json({ total: inbox.length });
  });

  return router;
}
