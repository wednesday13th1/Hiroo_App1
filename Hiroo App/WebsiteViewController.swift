import UIKit
import WebKit
import SafariServices

final class WebsiteViewController: UIViewController, WKNavigationDelegate {

    private enum Site: Int, CaseIterable {
        case koishikawa
        case hiroo

        var title: String {
            switch self {
            case .koishikawa: return NSLocalizedString("hgk", comment: "")
            case .hiroo: return NSLocalizedString("hg", comment: "")
            }
        }

        var url: URL {
            switch self {
            case .koishikawa: return URL(string: "https://hiroo-koishikawa.ed.jp/")!
            case .hiroo: return URL(string: "https://www.hiroogakuen.ed.jp/")!
            }
        }
    }

    // UI
    private let segmented = UISegmentedControl(items: Site.allCases.map { $0.title })
    private let webView = WKWebView(frame: .zero, configuration: {
        let cfg = WKWebViewConfiguration()
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        return cfg
    }())
    private let progressView = UIProgressView(progressViewStyle: .bar)
    private var refreshControl: UIRefreshControl!

    // Toolbar buttons
    private lazy var backItem = UIBarButtonItem(title: "戻る", style: .plain, target: self, action: #selector(goBack))
    private lazy var forwardItem = UIBarButtonItem(title: "進む", style: .plain, target: self, action: #selector(goForward))
    private lazy var reloadItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(reloadPage))
    private lazy var safariItem = UIBarButtonItem(title: "Safari", style: .plain, target: self, action: #selector(openInSafari))

    // State
    private var currentSite: Site = .koishikawa

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNavAndToolbar()
        setupWebView()
        setupSegmented()
        setupObservers()
        load(site: currentSite)
    }

    deinit {
        webView.removeObserver(self, forKeyPath: "estimatedProgress")
        webView.removeObserver(self, forKeyPath: "canGoBack")
        webView.removeObserver(self, forKeyPath: "canGoForward")
        webView.navigationDelegate = nil
    }

    // MARK: - Setup

    private func setupNavAndToolbar() {
        navigationItem.title = currentSite.title

        progressView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(progressView)
        NSLayoutConstraint.activate([
            progressView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 2)
        ])

        // Toolbar
        navigationController?.isToolbarHidden = false
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbarItems = [backItem, spacer, forwardItem, spacer, reloadItem, spacer, safariItem]
        updateToolbarState()
    }

    private func setupWebView() {
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: progressView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Pull to refresh
        refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(reloadPage), for: .valueChanged)
        webView.scrollView.refreshControl = refreshControl
    }

    private func setupSegmented() {
        segmented.selectedSegmentIndex = currentSite.rawValue
        segmented.addTarget(self, action: #selector(siteChanged), for: .valueChanged)
        segmented.backgroundColor = .secondarySystemBackground
        segmented.selectedSegmentTintColor = .systemGreen
        segmented.setContentHuggingPriority(.required, for: .vertical)

        // Place segmented in navigation bar as titleView for compact UI
        navigationItem.titleView = segmented
    }

    private func setupObservers() {
        webView.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "canGoBack", options: .new, context: nil)
        webView.addObserver(self, forKeyPath: "canGoForward", options: .new, context: nil)
    }

    // MARK: - Loading

    private func load(site: Site) {
        currentSite = site
        navigationItem.title = site.title
        let req = URLRequest(url: site.url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
        webView.load(req)
    }

    // MARK: - Actions

    @objc private func siteChanged() {
        guard let site = Site(rawValue: segmented.selectedSegmentIndex) else { return }
        load(site: site)
    }

    @objc private func goBack() {
        webView.goBack()
    }

    @objc private func goForward() {
        webView.goForward()
    }

    @objc private func reloadPage() {
        if webView.url == nil {
            load(site: currentSite)
        } else {
            webView.reload()
        }
    }

    @objc private func openInSafari() {
        let url = webView.url ?? currentSite.url
        let svc = SFSafariViewController(url: url)
        present(svc, animated: true)
    }

    private func updateToolbarState() {
        backItem.isEnabled = webView.canGoBack
        forwardItem.isEnabled = webView.canGoForward
    }

    // MARK: - Observing

    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            progressView.isHidden = webView.estimatedProgress >= 1.0
            progressView.setProgress(Float(webView.estimatedProgress), animated: true)
            if webView.estimatedProgress >= 1.0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                    self?.progressView.setProgress(0, animated: false)
                }
            }
        } else if keyPath == "canGoBack" || keyPath == "canGoForward" {
            updateToolbarState()
        }
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        refreshControl.endRefreshing()
        updateToolbarState()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        refreshControl.endRefreshing()
        updateToolbarState()
        showError(error)
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        refreshControl.endRefreshing()
        updateToolbarState()
        showError(error)
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "読み込みエラー",
                                      message: error.localizedDescription,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        if presentedViewController == nil {
            present(alert, animated: true)
        }
    }
}

