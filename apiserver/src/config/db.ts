import mysql from 'mysql2'
import mysql2 from 'mysql2/promise'
import { getUtils } from '../utils/getUtil'
import { Logger } from '../utils/logger'

export const dbConn = () => {
  return mysql.createConnection({
    host: getUtils().DB_HOST,
    user: getUtils().DB_USER,
    database: getUtils().DB_NAME,
    password: getUtils().DB_PASSWORD,
  })
}

export const dbConnPool = () => {
  return mysql2.createPool({
    host: getUtils().DB_HOST,
    user: getUtils().DB_USER,
    database: getUtils().DB_NAME,
    password: getUtils().DB_PASSWORD,
    connectTimeout: 5000,
    connectionLimit: 30,
    waitForConnections: true,
  })
}

export const connectionPing = () => {
  const conn = dbConn()
  conn.connect((err) => {
    if (err) {
      throw new Error(`db Connection Refuse : , ${err}`)
    }

    Logger.debug(`DB Connection... ${getUtils().DB_HOST}:${getUtils().DB_PORT}`)
    conn.query(
      `
        CREATE TABLE IF NOT EXISTS todos (
            id INT AUTO_INCREMENT PRIMARY KEY,
            title VARCHAR(255) NOT NULL,
            description TEXT,
            createAt INT NOT NULL
          );
        `
    )
  })
}
