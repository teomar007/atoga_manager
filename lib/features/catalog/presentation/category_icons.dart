import 'package:flutter/material.dart';

/// خيار أيقونة تصنيف: الاسم المخزَّن في `categories.icon_name` + الأيقونة
/// + تسميتان (عربية/فرنسية) + كلمات بحث إضافية. يجب أن تطابق هذه الأسماء
/// خريطة `iconFor` في تطبيق الزبون لتظهر الأيقونة نفسها هناك.
class CategoryIconOption {
  const CategoryIconOption(this.name, this.labelAr, this.labelFr, this.keywords, this.icon);

  final String name;
  final String labelAr;
  final String labelFr;

  /// كلمات إضافية للبحث (عربية/فرنسية/إنجليزية) مفصولة بمسافات.
  final String keywords;
  final IconData icon;
}

/// مجموعة أيقونات شاملة لمجال البقالة والأغذية والمنظفات والمنزل وغيرها.
const List<CategoryIconOption> kCategoryIcons = <CategoryIconOption>[
  // تسوّق ومتاجر
  CategoryIconOption('shopping_basket', 'سلة التسوق', 'Panier', 'سلة panier basket courses', Icons.shopping_basket),
  CategoryIconOption('shopping_cart', 'عربة التسوق', 'Chariot', 'عربة chariot cart panier', Icons.shopping_cart),
  CategoryIconOption('shopping_bag', 'كيس التسوق', 'Sac', 'كيس sac bag courses', Icons.shopping_bag),
  CategoryIconOption('storefront', 'واجهة متجر', 'Boutique', 'متجر boutique magasin storefront', Icons.storefront),
  CategoryIconOption('store', 'متجر', 'Magasin', 'متجر magasin store boutique', Icons.store),
  CategoryIconOption('local_grocery_store', 'بقالة', 'Épicerie', 'بقالة epicerie grocery alimentation', Icons.local_grocery_store),
  CategoryIconOption('local_convenience_store', 'دكان', 'Supérette', 'دكان superette convenience', Icons.local_convenience_store),
  CategoryIconOption('local_mall', 'مركز تجاري', 'Centre commercial', 'مول mall centre commercial', Icons.local_mall),

  // مطاعم ووجبات
  CategoryIconOption('restaurant', 'مطعم', 'Restaurant', 'مطعم restaurant', Icons.restaurant),
  CategoryIconOption('restaurant_menu', 'قائمة مطعم', 'Menu', 'قائمة menu carte', Icons.restaurant_menu),
  CategoryIconOption('local_dining', 'طعام', 'Restauration', 'طعام restauration dining repas', Icons.local_dining),
  CategoryIconOption('lunch_dining', 'وجبات / هامبرغر', 'Déjeuner / Burger', 'وجبات burger hamburger dejeuner lunch', Icons.lunch_dining),
  CategoryIconOption('dinner_dining', 'عشاء', 'Dîner', 'عشاء diner dinner souper', Icons.dinner_dining),
  CategoryIconOption('breakfast_dining', 'فطور', 'Petit-déjeuner', 'فطور petit dejeuner breakfast', Icons.breakfast_dining),
  CategoryIconOption('brunch_dining', 'برانش', 'Brunch', 'برانش brunch', Icons.brunch_dining),
  CategoryIconOption('fastfood', 'وجبات سريعة', 'Restauration rapide', 'سريعة fast food rapide snack', Icons.fastfood),
  CategoryIconOption('local_pizza', 'بيتزا', 'Pizza', 'بيتزا pizza', Icons.local_pizza),
  CategoryIconOption('takeout_dining', 'وجبات للخارج', 'À emporter', 'takeaway a emporter', Icons.takeout_dining),
  CategoryIconOption('room_service', 'خدمة الطلبات', 'Service', 'خدمة service', Icons.room_service),

  // لحوم وأسماك
  CategoryIconOption('kebab_dining', 'لحوم / مشاوي', 'Viandes / Grillades', 'لحم لحوم دجاج شاورما مشاوي viande viandes poulet kebab grillade', Icons.kebab_dining),
  CategoryIconOption('outdoor_grill', 'شواء', 'Barbecue', 'شواء مشاوي barbecue grill', Icons.outdoor_grill),
  CategoryIconOption('set_meal', 'سمك وأكل بحري', 'Poisson & fruits de mer', 'سمك حوت بحري poisson seafood', Icons.set_meal),

  // نشويات ومعكرونة وحساء
  CategoryIconOption('ramen_dining', 'معكرونة / نودلز', 'Pâtes / Nouilles', 'معكرونة نودلز pasta pates nouilles', Icons.ramen_dining),
  CategoryIconOption('rice_bowl', 'أرز', 'Riz', 'أرز riz rice', Icons.rice_bowl),
  CategoryIconOption('soup_kitchen', 'حساء / شوربة', 'Soupe', 'شوربة حساء soupe soup', Icons.soup_kitchen),
  CategoryIconOption('grain', 'حبوب وعجائن', 'Céréales', 'حبوب قمح cereales grain', Icons.grain),

  // مخبوزات وحلويات
  CategoryIconOption('bakery_dining', 'مخبوزات', 'Boulangerie', 'خبز مخبوزات boulangerie pain', Icons.bakery_dining),
  CategoryIconOption('cake', 'حلويات / كيك', 'Gâteaux', 'كيك حلويات gateau patisserie cake', Icons.cake),
  CategoryIconOption('icecream', 'مثلجات', 'Glaces', 'مثلجات ايسكريم glace icecream', Icons.icecream),
  CategoryIconOption('cookie', 'بسكويت', 'Biscuits', 'بسكويت biscuit cookie', Icons.cookie),

  // خضار وفواكه وفلاحة
  CategoryIconOption('grass', 'خضروات', 'Légumes', 'خضار خضروات legumes legume vegetable', Icons.grass),
  CategoryIconOption('agriculture', 'منتجات فلاحية', 'Produits agricoles', 'فلاحة زراعة agriculture ferme', Icons.agriculture),
  CategoryIconOption('local_florist', 'فواكه وزهور', 'Fruits & fleurs', 'فواكه فاكهة زهور fleurs fruits', Icons.local_florist),
  CategoryIconOption('eco', 'طبيعي / عضوي', 'Bio / Naturel', 'طبيعي عضوي bio naturel eco', Icons.eco),
  CategoryIconOption('park', 'حدائق', 'Parc', 'حديقة parc park jardin', Icons.park),
  CategoryIconOption('nature', 'طبيعة', 'Nature', 'طبيعة nature', Icons.nature),
  CategoryIconOption('filter_vintage', 'زهور', 'Fleurs', 'زهرة fleur flower', Icons.filter_vintage),

  // ألبان وبيض
  CategoryIconOption('egg', 'بيض', 'Œufs', 'بيض oeuf oeufs egg', Icons.egg),
  CategoryIconOption('egg_alt', 'أجبان وألبان', 'Fromages & lait', 'جبن حليب زبدة fromage lait beurre', Icons.egg_alt),

  // مشروبات
  CategoryIconOption('local_drink', 'مشروبات', 'Boissons', 'مشروب عصير boisson boissons jus drink', Icons.local_drink),
  CategoryIconOption('local_cafe', 'قهوة', 'Café', 'قهوة cafe coffee', Icons.local_cafe),
  CategoryIconOption('coffee', 'قهوة ساخنة', 'Café chaud', 'قهوة cafe coffee', Icons.coffee),
  CategoryIconOption('coffee_maker', 'آلة قهوة', 'Machine à café', 'قهوة cafe machine', Icons.coffee_maker),
  CategoryIconOption('emoji_food_beverage', 'شاي', 'Thé', 'شاي the tea', Icons.emoji_food_beverage),
  CategoryIconOption('local_bar', 'مشروبات متنوعة', 'Boissons diverses', 'مشروب bar boisson', Icons.local_bar),
  CategoryIconOption('sports_bar', 'مشروبات رياضية', 'Boissons sportives', 'مشروب sport boisson', Icons.sports_bar),
  CategoryIconOption('liquor', 'كحول', 'Alcool', 'كحول alcool liquor', Icons.liquor),
  CategoryIconOption('wine_bar', 'نبيذ', 'Vin', 'نبيذ vin wine', Icons.wine_bar),
  CategoryIconOption('water_drop', 'ماء', 'Eau', 'ماء eau water', Icons.water_drop),
  CategoryIconOption('water', 'مياه', 'Eaux', 'مياه ماء eau water', Icons.water),
  CategoryIconOption('ac_unit', 'تجميد / مجمد', 'Congélation / Surgelés', 'تجميد مجمد مثلج congelation surgele freeze', Icons.ac_unit),

  // مطبخ وأدوات
  CategoryIconOption('kitchen', 'مطبخ', 'Cuisine', 'مطبخ cuisine kitchen', Icons.kitchen),
  CategoryIconOption('blender', 'خلاط', 'Mixeur', 'خلاط mixeur blender', Icons.blender),
  CategoryIconOption('microwave', 'ميكروويف', 'Micro-ondes', 'ميكروويف micro-ondes four', Icons.microwave),
  CategoryIconOption('countertops', 'أسطح المطبخ', 'Plans de travail', 'مطبخ plan cuisine comptoir', Icons.countertops),

  // منظفات وعناية بالمنزل
  CategoryIconOption('cleaning_services', 'منظفات', 'Nettoyage', 'منظفات تنظيف nettoyage menage', Icons.cleaning_services),
  CategoryIconOption('soap', 'صابون', 'Savon', 'صابون savon soap', Icons.soap),
  CategoryIconOption('local_laundry_service', 'غسيل الملابس', 'Blanchisserie', 'غسيل مسحوق lessive blanchisserie laundry', Icons.local_laundry_service),
  CategoryIconOption('dishwasher', 'غسالة أطباق', 'Lave-vaisselle', 'جلي lave vaisselle', Icons.wash),
  CategoryIconOption('dry_cleaning', 'تنظيف جاف', 'Nettoyage à sec', 'تنظيف sec', Icons.dry_cleaning),
  CategoryIconOption('wash', 'غسل اليدين', 'Lavage des mains', 'غسل lavage savon', Icons.wash),
  CategoryIconOption('sanitizer', 'مطهّر', 'Désinfectant', 'مطهر desinfectant', Icons.sanitizer),
  CategoryIconOption('recycle', 'إعادة تدوير', 'Recyclage', 'تدوير recyclage', Icons.loop),

  // أطفال وصحة وعناية شخصية
  CategoryIconOption('child_friendly', 'أطفال', 'Enfants', 'طفل اطفال enfant bebe', Icons.child_friendly),
  CategoryIconOption('child_care', 'عناية بالأطفال', 'Puériculture', 'رضيع حفاض bebe enfant couche', Icons.child_care),
  CategoryIconOption('face', 'عناية شخصية', 'Soins personnels', 'تجميل جمال soin beaute cosmetique', Icons.face),
  CategoryIconOption('spa', 'سبا / استرخاء', 'Spa / Détente', 'سبا استرخاء spa detente', Icons.spa),
  CategoryIconOption('health_and_safety', 'صحة وسلامة', 'Santé & sécurité', 'صحة sante health', Icons.health_and_safety),
  CategoryIconOption('medical_services', 'طبي / صيدلية', 'Médical / Pharmacie', 'دواء صيدلية pharmacie medical', Icons.medical_services),
  CategoryIconOption('medication', 'أدوية', 'Médicaments', 'دواء medicament', Icons.medication),
  CategoryIconOption('vaccines', 'لقاحات', 'Vaccins', 'لقاح vaccin', Icons.vaccines),
  CategoryIconOption('local_pharmacy', 'صيدلية', 'Pharmacie', 'صيدلية pharmacie', Icons.local_pharmacy),

  // حيوانات أليفة
  CategoryIconOption('pets', 'حيوانات أليفة', 'Animaux', 'حيوان قطة كلب animal animaux pet', Icons.pets),

  // منزل ومفروشات وإضاءة
  CategoryIconOption('home', 'منزل', 'Maison', 'منزل maison home', Icons.home),
  CategoryIconOption('house', 'بيت', 'Maison', 'بيت maison', Icons.house),
  CategoryIconOption('dining', 'غرفة الطعام', 'Salle à manger', 'طعام salle a manger repas', Icons.dining),
  CategoryIconOption('chair', 'كراسي', 'Chaises', 'كرسي chaise chair', Icons.chair),
  CategoryIconOption('bed', 'مفروشات', 'Literie', 'سرير lit couverture', Icons.bed),
  CategoryIconOption('light', 'إضاءة', 'Éclairage', 'مصباح lampe lumiere', Icons.light),
  CategoryIconOption('bolt', 'كهرباء', 'Électricité', 'كهرباء electricite', Icons.bolt),

  // توصيل وهدايا ومتفرقات
  CategoryIconOption('local_shipping', 'توصيل', 'Livraison', 'توصيل livraison shipping', Icons.local_shipping),
  CategoryIconOption('delivery_dining', 'توصيل طلبات', 'Livraison repas', 'توصيل livraison', Icons.delivery_dining),
  CategoryIconOption('card_giftcard', 'بطاقة هدية', 'Carte cadeau', 'هدية cadeau gift', Icons.card_giftcard),
  CategoryIconOption('redeem', 'هدايا', 'Cadeaux', 'هدية cadeau', Icons.redeem),
  CategoryIconOption('celebration', 'مناسبات', 'Célébrations', 'عيد حفلة fete celebration', Icons.celebration),
  CategoryIconOption('toys', 'ألعاب أطفال', 'Jouets', 'لعبة jouet', Icons.toys),
  CategoryIconOption('sports_esports', 'ألعاب إلكترونية', 'Jeux vidéo', 'ألعاب jeux', Icons.sports_esports),
  CategoryIconOption('menu_book', 'كتب وقرطاسية', 'Livres & papeterie', 'كتاب livre lecture', Icons.menu_book),
  CategoryIconOption('palette', 'فنون وأشغال', 'Arts', 'فن art', Icons.palette),
  CategoryIconOption('brush', 'رسم', 'Peinture', 'رسم peinture', Icons.brush),
];

/// أيقونة التصنيف من اسمها المخزَّن، مع أيقونة افتراضية عند الجهل بها.
IconData categoryIconFor(String? name) {
  for (final CategoryIconOption option in kCategoryIcons) {
    if (option.name == name) {
      return option.icon;
    }
  }
  return Icons.grid_view_rounded;
}
