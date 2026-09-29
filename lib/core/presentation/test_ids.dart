/// Automation IDs (handheld spec decision 6) — the single source for both
/// `TestId` wrappers in widgets and `byTestId` / `bySemanticsIdentifier`
/// finders in tests. Format: `<screen>.<element>` in lowerCamel. Android
/// exposes these as `resource-id`, iOS as `accessibilityIdentifier`.
///
/// Add new IDs here in the screen's group; never inline string literals.
abstract class NavIds {
  static const home = 'nav.home';
  static const sale = 'nav.sale';
  static const enquiry = 'nav.enquiry';
  static const menu = 'nav.menu';
}

abstract class MenuIds {
  static const sheet = 'menu.sheet';
  static const settings = 'menu.settings';
  static const logout = 'menu.logout';
}

abstract class LoginIds {
  static const userCodeField = 'login.userCodeField';
  static const passwordField = 'login.passwordField';
  static const passwordVisibility = 'login.passwordVisibility';
  static const signInButton = 'login.signInButton';
  static const qrLoginButton = 'login.qrLoginButton';
  static const settingsButton = 'login.settingsButton';
  static const errorMessage = 'login.errorMessage';
}

abstract class HomeIds {
  static const greeting = 'home.greeting';
  static const sessionLine = 'home.sessionLine';
  static const onlineStatus = 'home.onlineStatus';
  static const billsStat = 'home.billsStat';
  static const netSalesStat = 'home.netSalesStat';
  static const scanField = 'home.scanField';
  static const tileRegister = 'home.tile.register';
  static const tileSale = 'home.tile.sale';
  static const tileCheckout = 'home.tile.checkout';
  static const tileEnquiry = 'home.tile.enquiry';
  static const suspendedBills = 'home.suspendedBills';
  static const customerResult = 'home.customerResult';
}

abstract class SettingsIds {
  static const saveButton = 'settings.saveButton';
  static const cancelButton = 'settings.cancelButton';
  static const terminalSection = 'settings.terminalSection';
  static const saleModeSection = 'settings.saleModeSection';
  static const sellOnline = 'settings.saleMode.online';
  static const sellOffline = 'settings.saleMode.offline';
  static const endpointsSection = 'settings.endpointsSection';
  static const deviceSection = 'settings.deviceSection';
}

abstract class SaleIds {
  static const header = 'sale.header';
  static const backButton = 'sale.backButton';
  static const scanField = 'sale.scanField';
  static const scanError = 'sale.scanError';
  static const staleNotice = 'sale.staleNotice';
  static const totalLine = 'sale.totalLine';
  static const netPay = 'sale.netPay';
  static const tabBuying = 'sale.tab.buying';
  static const tabBasket = 'sale.tab.basket';
  static const backToBuyingButton = 'sale.backToBuyingButton';
  static const emptyState = 'sale.emptyState';
  static const privilege = 'sale.privilege';
  static const basketNotice = 'sale.basketNotice';
  static const checkoutButton = 'sale.checkoutButton';
  static const customerButton = 'sale.customerButton';
  static const discountButton = 'sale.discountButton';
  static const saveButton = 'sale.saveButton';
  static const moreButton = 'sale.moreButton';
  static const moreSheet = 'sale.moreSheet';
  static const orderTypeShopping = 'sale.orderType.shopping';
  static const orderTypeDelivery = 'sale.orderType.delivery';
  static const orderTypePreOrder = 'sale.orderType.preOrder';
  static const voidConfirm = 'sale.voidConfirm';

  /// One cart line, keyed by its cart `row`.
  static String line(String row) => 'sale.line.$row';
}

abstract class EditLineIds {
  static const page = 'editLine.page';
  static const undoButton = 'editLine.undoButton';
  static const saveButton = 'editLine.saveButton';
  static const saveCloseButton = 'editLine.saveCloseButton';
  static const qtyDecrease = 'editLine.qty.decrease';
  static const qtyIncrease = 'editLine.qty.increase';
  static const qtyValue = 'editLine.qty.value';
  static const amount = 'editLine.amount';
  static const netAmount = 'editLine.netAmount';
  static const serialField = 'editLine.serialField';
  static const freezeSwitch = 'editLine.freezeSwitch';
  static const lockDiscountSwitch = 'editLine.lockDiscountSwitch';
  static const pickupCollect = 'editLine.pickup.collect';
  static const pickupTake = 'editLine.pickup.take';
  static const voidButton = 'editLine.voidButton';
}

abstract class DiscountIds {
  static const sheet = 'discount.sheet';
  static const closeButton = 'discount.closeButton';
  static const modePercent = 'discount.mode.percent';
  static const modeAmount = 'discount.mode.amount';
  static const modePromo = 'discount.mode.promo';
  static const valueField = 'discount.valueField';
  static const netPreview = 'discount.netPreview';
  static const applyButton = 'discount.applyButton';
  static const cancelButton = 'discount.cancelButton';

  static String preset(int percent) => 'discount.preset.$percent';
}

abstract class CheckoutIds {
  static const page = 'checkout.page';
  static const netPay = 'checkout.netPay';
  static const summaryLine = 'checkout.summaryLine';
  static const flagsNotice = 'checkout.flagsNotice';
  static const customerCard = 'checkout.customerCard';
  static const amountsCard = 'checkout.amountsCard';
  static const totalAmount = 'checkout.amount.total';
  static const grandAmount = 'checkout.amount.grand';
  static const signatureRow = 'checkout.signatureRow';
  static const takePaymentButton = 'checkout.takePaymentButton';
  static const suspendButton = 'checkout.suspendButton';
  static const printQuoteButton = 'checkout.printQuoteButton';
}

abstract class PaymentIds {
  static const page = 'payment.page';
  static const netPay = 'payment.netPay';
  static const tendered = 'payment.tendered';
  static const remaining = 'payment.remaining';
  static const amountField = 'payment.amountField';
  static const presetAllRemaining = 'payment.preset.allRemaining';
  static const presetHalf = 'payment.preset.half';
  static const preset10000 = 'payment.preset.10000';
  static const preset20000 = 'payment.preset.20000';
  static const ledger = 'payment.ledger';
  static const ledgerEmpty = 'payment.ledgerEmpty';
  static const chargeButton = 'payment.chargeButton';
  static const completeSaleButton = 'payment.completeSaleButton';
  static const chargeNotice = 'payment.chargeNotice';

  static String method(String name) => 'payment.method.$name';
  static String ledgerRow(int index) => 'payment.ledger.$index';
}

abstract class WalletIds {
  static const scanPage = 'wallet.scanPage';
  static const chargeAmount = 'wallet.chargeAmount';
  static const codeField = 'wallet.codeField';
  static const detectedCode = 'wallet.detectedCode';
  static const unknownCode = 'wallet.unknownCode';
  static const sendChargeButton = 'wallet.sendChargeButton';
  static const cancelButton = 'wallet.cancelButton';
  static const rescanButton = 'wallet.rescanButton';
  static const showQrButton = 'wallet.showQrButton';

  static String step(String name) => 'wallet.step.$name';

  static const queryPage = 'wallet.queryPage';
  static const queryButton = 'wallet.queryButton';
  static const queryResult = 'wallet.queryResult';
  static const voidButton = 'wallet.voidButton';
  static const printButton = 'wallet.printButton';

  static const voidPage = 'wallet.voidPage';
  static const voidAmount = 'wallet.voidAmount';
  static const voidReason = 'wallet.voidReason';
  static const managerApproval = 'wallet.managerApproval';
  static const confirmVoidButton = 'wallet.confirmVoidButton';
}

abstract class SignatureIds {
  static const page = 'signature.page';
  static const closeButton = 'signature.closeButton';
  static const saveButton = 'signature.saveButton';
  static const bottomSaveButton = 'signature.bottomSaveButton';
  static const cancelButton = 'signature.cancelButton';
  static const paidByPad = 'signature.paidBy.pad';
  static const paidByClear = 'signature.paidBy.clear';
  static const paidByStatus = 'signature.paidBy.status';
  static const customerPad = 'signature.customer.pad';
  static const customerClear = 'signature.customer.clear';
  static const customerStatus = 'signature.customer.status';
}
