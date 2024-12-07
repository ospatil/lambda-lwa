import { serve } from '@hono/node-server'
import { Hono } from 'hono'
import process from 'node:process'

// SIGTERM Handler. Lambda service will call it when it wants to shut down the Lambda execution environment.
process.on('SIGTERM', async () => {
  console.info('SIGTERM received');
  // perform actual clean up work here.
  console.info('exiting');
  process.exit(0)
});

const app = new Hono()
app.get('*', (c) => {
  console.info('Received request = ', JSON.stringify(c.req))
  return c.text('Hello, World!')
})

const portStr = process.env['PORT']

const port = portStr ? parseInt(portStr, 10) : 8080
console.info(`Server is running on http://localhost:${port}`)

serve({
  fetch: app.fetch,
  port
})
