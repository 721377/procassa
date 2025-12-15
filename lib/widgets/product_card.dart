import 'package:flutter/material.dart';
import 'package:procassa/models.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isSelectable;
  final VoidCallback? onAdd;
  final int? quantity;
  final bool? isInCart;
  final String? selectedPrice;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isSelectable = false,
    this.onAdd,
    this.quantity,
    this.isInCart = false,
    this.selectedPrice,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPhone = MediaQuery.of(context).size.width < 600;

    return GestureDetector(
        onTap: onTap,
        child: Container(
          height: isPhone ? 70 : 85,
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(
              horizontal: 8, vertical: 6), // smaller padding
          decoration: BoxDecoration(
            color: isInCart == true ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isInCart == true
                  ? const Color(0xFF3573EF)
                  : const Color(0xFFE5E7EB),
              width: isInCart == true ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedPrice ?? '€${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: isPhone ? 13 : 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D6FF1),
                      ),
                      overflow: TextOverflow.ellipsis, // 👈 prevent overflow
                    ),
                  ),
                  if (isInCart == true && quantity != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D6FF1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'x$quantity',
                        style: TextStyle(
                          fontSize: isPhone ? 10 : 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isPhone ? 13 : 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF111827),
                  height: 1.15,
                ),
              ),
            ],
          ),
        ));
  }
}
