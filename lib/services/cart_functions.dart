import '../models.dart';

class CartFunctions {
  static void addToCart(List<CartItem> cartItems, Product product, {int quantity = 1}) {
    // Find item with same ID AND same price
    final int existingIndex = cartItems.indexWhere(
      (item) => item.product.id == product.id && item.product.price == product.price,
    );

    if (existingIndex != -1) {
      cartItems[existingIndex].quantity += quantity;
    } else {
      cartItems.add(CartItem(product: product, quantity: quantity));
    }
  }

  static void addToCartWithCustomPrice(List<CartItem> cartItems, Product product, double price) {
    final customProduct = product.copyWith(price: price);
    
    // Even for custom price, if an item with same ID and same custom price exists, update quantity
    final int existingIndex = cartItems.indexWhere(
      (item) => item.product.id == customProduct.id && item.product.price == customProduct.price,
    );

    if (existingIndex != -1) {
      cartItems[existingIndex].quantity += 1;
    } else {
      cartItems.add(CartItem(product: customProduct));
    }
  }

  static void removeFromCart(List<CartItem> cartItems, String productId, [double? price]) {
    if (price != null) {
      cartItems.removeWhere((item) => item.product.id == productId && item.product.price == price);
    } else {
      cartItems.removeWhere((item) => item.product.id == productId);
    }
  }

  static void updateQuantity(List<CartItem> cartItems, String productId, int newQuantity, [double? price]) {
    final int index = cartItems.indexWhere(
      (item) => item.product.id == productId && (price == null || item.product.price == price),
    );
    
    if (index != -1) {
      if (newQuantity > 0) {
        cartItems[index].quantity = newQuantity;
      } else {
        cartItems.removeAt(index);
      }
    }
  }

  static void clearCart(List<CartItem> cartItems) {
    cartItems.clear();
  }
}
