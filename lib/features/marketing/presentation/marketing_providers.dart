import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/supabase_provider.dart';
import '../data/marketing_repository.dart';
import '../domain/marketing_models.dart';

final marketingRepositoryProvider = Provider<MarketingRepository>(
  (Ref ref) => MarketingRepository(ref.watch(supabaseClientProvider)),
);

final marketingBannersProvider = FutureProvider<List<MarketingBanner>>(
  (Ref ref) => ref.watch(marketingRepositoryProvider).fetchBanners(),
);

final marketingCouponsProvider = FutureProvider<List<MarketingCoupon>>(
  (Ref ref) => ref.watch(marketingRepositoryProvider).fetchCoupons(),
);

final marketingCampaignsProvider = FutureProvider<List<CampaignRecord>>(
  (Ref ref) => ref.watch(marketingRepositoryProvider).fetchCampaigns(),
);

final scheduledNotificationsProvider = FutureProvider<List<ScheduledNotification>>(
  (Ref ref) => ref.watch(marketingRepositoryProvider).fetchScheduled(),
);
