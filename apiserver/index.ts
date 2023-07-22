import cors from 'cors'
import express from 'express'
import fs from 'fs'
import morgan from 'morgan'
import { connectionPing } from './src/config/db'
import { healthCheckController } from './src/healthCheck/index.controller'
import { todoController } from './src/todo/index.controller'
import { getUtils } from './src/utils/getUtil'
import { Logger } from './src/utils/logger'

const app = express()

//////////////////////////////// connection ////////////////////////////////
if (!fs.existsSync('logs')) {
  fs.mkdirSync('logs')
}

connectionPing()

//////////////////////////////// middleware ////////////////////////////////
app.use(morgan('tiny'))
app.use(cors())
app.use(express.json())

//////////////////////////////// router ////////////////////////////////
app.use(healthCheckController.router)
app.use(todoController.router)

//////////////////////////////// App ////////////////////////////////
app.listen(getUtils().PORT, () => {
  Logger.debug(`${getUtils().PORT} is running`)
})
