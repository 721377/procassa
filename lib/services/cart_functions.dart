import '../models.dart';

class CartFunctions {
  static void addToCart(List<CartItem> cartItems, Product product, {int quantity = 1}) {
    final existingItem = cartItems.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(
        product: Product(
          id: '',
          name: '',
          category: '',
          price: 0,
          description: '',
        ),
      ),
    );

    if (existingItem.product.id.isNotEmpty) {
      existingItem.quantity += quantity;
    } else {
      cartItems.add(CartItem(product: product, quantity: quantity));
    }
  }

  static void addToCartWithCustomPrice(List<CartItem> cartItems, Product product, double price) {
    final customProduct = Product(
      id: product.id,
      name: product.name,
      category: product.category,
      price: price,
      description: product.description,
    );

    cartItems.add(CartItem(product: customProduct));
  }

  static void removeFromCart(List<CartItem> cartItems, String productId) {
    cartItems.removeWhere((item) => item.product.id == productId);
  }

  static void updateQuantity(List<CartItem> cartItems, String productId, int newQuantity) {
    final item = cartItems.firstWhere((item) => item.product.id == productId);
    if (newQuantity > 0) {
      item.quantity = newQuantity;
    } else {
      removeFromCart(cartItems, productId);
    }
  }

  static void clearCart(List<CartItem> cartItems) {
    cartItems.clear();
  }
}
