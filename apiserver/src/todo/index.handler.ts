//////////////////////////////// Get Todos ////////////////////////////////

import dayjs from 'dayjs'
import { dbConnPool } from '../config/db'
import { Logger } from '../utils/logger'

const co = dbConnPool().getConnection()

export const handleGetTodos = async () =>
  co
    .then((conn) =>
      conn.query(
        `
        select 
        id,
        title,
        description,
        createAt
        from todos
    `
      )
    )
    .then((res) => [res][0][0])
    .catch((err) => Logger.debug(err))

//////////////////////////////// Create Todos ////////////////////////////////
interface CreateTodoParams {
  title: string
  desc: string
}
export const handleCreateTodos = ({ title, desc }: CreateTodoParams) =>
  co
    .then((conn) => {
      conn.query(
        `
            insert into 
            todos(title, description, createAt)
            values(?,?,?)            
        `,
        [title, desc, dayjs().unix()]
      )
    })
    .then(() => 'success')
    .catch((err) => Logger.debug(err))

//////////////////////////////// Delete Todos ////////////////////////////////
interface DeleteTodoParams {
  id: string
}
export const handleDeleteTodos = ({ id }: DeleteTodoParams) => {
  co.then((conn) => {
    conn.query(
      `
        delete 
        from todos
        where id = ?  
      `,
      [id]
    )
  })
    .then(() => 'success')
    .catch((err) => Logger.debug(err))
}
