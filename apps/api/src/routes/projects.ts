import { Request, Response, Router, NextFunction } from 'express';
import { ProjectService } from '../services/project.service';

type AsyncHandler = (req: Request, res: Response) => Promise<void>;

const wrap =
  (handler: AsyncHandler) =>
  (req: Request, res: Response, next: NextFunction): void => {
    handler(req, res).catch(next);
  };

const parseId = (value: string): number => {
  const id = Number(value);
  if (!Number.isInteger(id) || id <= 0) {
    return -1;
  }
  return id;
};

export function projectsRouter(service: ProjectService): Router {
  const router = Router();

  router.get(
    '/',
    wrap(async (_req, res) => {
      res.json(await service.list());
    })
  );

  router.get(
    '/:id',
    wrap(async (req, res) => {
      res.json(await service.getById(parseId(req.params.id)));
    })
  );

  router.post(
    '/',
    wrap(async (req, res) => {
      const created = await service.create(req.body);
      res.status(201).json(created);
    })
  );

  router.delete(
    '/:id',
    wrap(async (req, res) => {
      await service.remove(parseId(req.params.id));
      res.status(204).end();
    })
  );

  return router;
}
