const express = require('express')
const bodyParser = require('body-parser')
const jwt = require('jsonwebtoken')
const app = express()
app.use(bodyParser.json())

const JWT_SECRET = process.env.JWT_SECRET || 'dev_secret'

// demo in-memory users
const users = [{ id: 1, username: 'demo', password: 'demo' }]

app.post('/api/auth/register', (req, res) => {
  const { username, password } = req.body
  if (!username || !password) return res.status(400).json({ error: 'missing' })
  const id = users.length + 1
  users.push({ id, username, password })
  res.json({ id, username })
})

app.post('/api/auth/login', (req, res) => {
  const { username, password } = req.body
  const u = users.find(x => x.username === username && x.password === password)
  if (!u) return res.status(401).json({ error: 'invalid' })
  const token = jwt.sign({ sub: u.id, username: u.username }, JWT_SECRET, { expiresIn: '1h' })
  res.json({ token })
})

app.get('/api/auth/me', (req, res) => {
  const auth = req.headers.authorization || ''
  const token = auth.replace(/^Bearer\s+/, '')

  try {
    const data = jwt.verify(token, JWT_SECRET)
    res.json({ user: data })
  } catch (e) {
    res.status(401).json({ error: 'invalid token' })
  }
})  // <-- FIXED CLOSING

const port = process.env.PORT || 4001
app.listen(port, () => console.log('auth-service listening', port))
