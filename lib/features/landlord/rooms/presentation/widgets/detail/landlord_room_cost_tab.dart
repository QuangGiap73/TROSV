import 'package:flutter/material.dart';

import '../../../domain/entities/landlord_room_detail.dart';
import 'landlord_room_ui.dart';

class LandlordRoomCostTab extends StatelessWidget {
  const LandlordRoomCostTab({
    required this.room,
    required this.onRefresh,
    super.key,
  });

  final LandlordRoomDetail room;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: roomGreen,
      onRefresh: onRefresh,
      child: ListView(
        key: const PageStorageKey('landlord-room-cost'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          if (room.cost == null)
            const _EmptyCost()
          else
            _CostContent(cost: room.cost!),
        ],
      ),
    );
  }
}

class _CostContent extends StatelessWidget {
  const _CostContent({required this.cost});

  final LandlordRoomCost cost;

  @override
  Widget build(BuildContext context) {
    final items = <_CostItem>[
      _CostItem(
        Icons.bolt_rounded,
        'Tiền điện',
        utilityPrice(
          type: cost.electricityType,
          price: cost.electricityPrice,
          electricity: true,
        ),
      ),
      _CostItem(
        Icons.water_drop_outlined,
        'Tiền nước',
        utilityPrice(
          type: cost.waterType,
          price: cost.waterPrice,
          electricity: false,
        ),
      ),
      _CostItem(Icons.wifi_rounded, 'Internet', _monthly(cost.internetFee)),
      _CostItem(Icons.two_wheeler_rounded, 'Gửi xe', _monthly(cost.parkingFee)),
      _CostItem(
        Icons.receipt_long_outlined,
        'Phí dịch vụ',
        _monthly(cost.serviceFee),
      ),
      _CostItem(
        Icons.cleaning_services_outlined,
        'Phí vệ sinh',
        _monthly(cost.cleaningFee),
      ),
      _CostItem(Icons.more_horiz_rounded, 'Phí khác', _monthly(cost.otherFee)),
    ];

    return LandlordRoomSectionCard(
      title: 'Chi phí sinh hoạt',
      icon: Icons.account_balance_wallet_outlined,
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _CostRow(item: items[index]),
            if (index != items.length - 1)
              const Divider(height: 20, color: Color(0xFFF0F3F2)),
          ],
          if (cost.otherDescription?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F9F8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                cost.otherDescription!,
                style: const TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: roomMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _monthly(int value) {
    return value == 0 ? '0 đ/tháng' : '${roomMoney(value)} đ/tháng';
  }
}

class _CostItem {
  const _CostItem(this.icon, this.label, this.value);

  final IconData icon;
  final String label;
  final String value;
}

class _CostRow extends StatelessWidget {
  const _CostRow({required this.item});

  final _CostItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8F5),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(item.icon, size: 20, color: roomGreenDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            item.label,
            style: const TextStyle(fontSize: 12.5, color: roomMuted),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            item.value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: roomText,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyCost extends StatelessWidget {
  const _EmptyCost();

  @override
  Widget build(BuildContext context) {
    return LandlordRoomSectionCard(
      title: 'Chi phí sinh hoạt',
      icon: Icons.account_balance_wallet_outlined,
      child: const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'Phòng chưa cập nhật chi phí sinh hoạt.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: roomMuted),
          ),
        ),
      ),
    );
  }
}
