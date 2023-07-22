import { Request, Response, Router } from 'express'
import { reqMiddleware } from '../middlewares/reqMiddleware'
class HealthCheckController {
  router: Router

  constructor() {
    this.router = Router()
    this.router.get('/health', reqMiddleware, this.healthCheck)
  }

  healthCheck(req: Request, res: Response) {
    return res.status(200).json('success')
  }
}

export const healthCheckController = new HealthCheckController()
