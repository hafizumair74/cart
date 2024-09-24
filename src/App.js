import React, { useState } from 'react'
import data from './components/data';
import Products from './components/Products';

function App() {

  //assigning the api data to new variable
  const { products } = data;

  //hook for adding data into cart
  const [ cartItems, setCartItems ] = useState([]);

  //function for adding product into cart. Also use to increment the product quantity
  const onAdd = (product) => {
    //checking if the product is already exist or not
    const exist = cartItems.find((x) => x.id === product.id);
    if(exist){
      setCartItems(cartItems.map((x) => x.id === product.id ? {...exist, qty:exist.qty + 1}:x));
      console.log(cartItems);
    }else{
      setCartItems([...cartItems,{...product, qty:1}]);
      console.log(cartItems);
    }
  }

  return (
    <div>
      <Products prodct={products} addpro={onAdd} />
    </div>
  )
}

export default App