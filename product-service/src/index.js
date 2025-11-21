const express = require('express')
const app = express()
app.use(express.json())


let products = [
{id:1, name:'Laptop', price:1299.99},
{id:2, name:'Headphones', price:199.99}
]


app.get('/api/products', (req,res)=> res.json(products))
app.post('/api/products', (req,res)=>{
const id = products.length+1
const p = {id, ...req.body}
products.push(p)
res.json(p)
})


const port = process.env.PORT || 4002
app.listen(port, ()=>console.log('product-service listening', port))