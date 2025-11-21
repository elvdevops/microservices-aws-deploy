import React, {useEffect, useState} from 'react'
import { createRoot } from 'react-dom/client'


function App(){
const [products, setProducts] = useState([])
const [token, setToken] = useState(null)


useEffect(()=>{
fetch('/api/products')
.then(r=>r.json())
.then(setProducts)
}, [])


const login = async ()=>{
const res = await fetch('/api/auth/login', {
method:'POST',
headers:{'Content-Type':'application/json'},
body: JSON.stringify({username:'demo', password:'demo'})
})
const data = await res.json()
setToken(data.token)
}


return (
React.createElement('div',{style:{fontFamily:'sans-serif',padding:20}},
React.createElement('h1',null,'Microservices Demo'),
React.createElement('button',{onClick:login},'Login as demo'),
React.createElement('h2',null,'Products'),
React.createElement('ul',null, products.map(p=>React.createElement('li',{key:p.id},`${p.name} — $${p.price}`)))
)
)
}


createRoot(document.getElementById('root')).render(React.createElement(App))