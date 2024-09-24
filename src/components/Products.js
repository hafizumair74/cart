import React from 'react'

function Products(props) {
    const { prodct, addpro } = props;
   
  return (
    <div className='container'>
        <h1 className='text-center display-3'>List of All Products</h1>
        <div className='row'>
      {
          prodct.map((prod) => (
              <div className='col-md-4 mb-4'>
            <div class="card">
            <img class="card-img-top" src={prod.image} style={{ height:'450px' }} />
            <div class="card-body">
              <h5 class="card-title">{prod.name}</h5>
              <p class="card-text">Rs, {prod.price}</p>
              <button className='btn btn-primary' onClick={() => addpro(prod)}>Add To Cart</button>
            </div>
          </div>
          </div>
          ))}
        </div>
    </div>
  )
}

export default Products