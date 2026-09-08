import Combine
import Foundation

/// Drives one catalog tab in `ColorCatalogBrowserView`. Generic over the concrete
/// `ColorDataProtocol` type so Pantone/IKEA/RAL/Sherwin-Williams share one implementation
/// instead of four near-identical view models.
///
/// `searchText` is debounced before it feeds `filteredColors`: these catalogs hold
/// 200–1000+ entries, so filtering on every keystroke would re-scan the array each frame.
@MainActor
final class ColorCatalogViewModel<T: ColorDataProtocol>: ObservableObject {
    @Published var catalog: [T]
    @Published var searchText: String = ""
    @Published var selectedColor: T?

    @Published private var debouncedSearchText: String = ""
    private var cancellable: AnyCancellable?

    init(catalog: [T], debounce: DispatchQueue.SchedulerTimeType.Stride = .milliseconds(250)) {
        self.catalog = catalog
        cancellable = $searchText
            .removeDuplicates()
            .debounce(for: debounce, scheduler: DispatchQueue.main)
            .sink { [weak self] text in
                self?.debouncedSearchText = text
            }
    }

    var filteredColors: [T] {
        guard !debouncedSearchText.isEmpty else { return catalog }
        return catalog.filter { color in
            color.name.localizedCaseInsensitiveContains(debouncedSearchText) ||
            color.id.localizedCaseInsensitiveContains(debouncedSearchText)
        }
    }
}
