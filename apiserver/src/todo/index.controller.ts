import { Request, Response, Router } from 'express'
import { reqMiddleware } from '../middlewares/reqMiddleware'
import { responseJson } from '../utils/fp/response'
import { handleCreateTodos, handleDeleteTodos, handleGetTodos } from './index.handler'
class TodoController {
  router: Router

  constructor() {
    this.router = Router()
    this.router.get('/todos', reqMiddleware, this.getTodos)
    this.router.post('/todos', reqMiddleware, this.createTodos)
    // this.router.put('/todos', reqMiddleware, this.healthCheck) 귀찮
    this.router.delete('/todos', reqMiddleware, this.deleteTodos)
  }

  async getTodos(req: Request, res: Response) {
    return responseJson({ res, data: await handleGetTodos(), status: 200 })
  }

  async createTodos(req: Request, res: Response) {
    return responseJson({ res, data: await handleCreateTodos(req.body), status: 200 })
  }

  async deleteTodos(req: Request, res: Response) {
    return responseJson({ res, data: await handleDeleteTodos(req.body), status: 200 })
  }
}

export const todoController = new TodoController()
