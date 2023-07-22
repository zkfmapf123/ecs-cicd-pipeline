import { Response } from 'express'
import { Logger } from '../logger'

interface Props<T> {
  res: Response
  data: T
  status: number
}

export const responseJson = <T>({ res, data, status }: Props<T>) => {
  Logger.debug(JSON.stringify(data))
  return res.status(status).json({ data })
}
