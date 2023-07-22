import { NextFunction, Request, Response } from 'express'
import { Logger } from '../utils/logger'

export const reqMiddleware = (req: Request, res: Response, next: NextFunction) => {
  Logger.debug(
    JSON.stringify({
      host: req.headers['host'],
      userAgent: req.headers['user-agent'],
      body: req.body,
    })
  )
  return next()
}
