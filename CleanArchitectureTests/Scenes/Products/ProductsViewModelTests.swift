//
//  ProductsViewModelTests.swift
//  CleanArchitecture
//
//  Created by Tuan Truong on 6/5/18.
//  Copyright © 2018 Sun Asterisk. All rights reserved.
//

@testable import CleanArchitecture
import XCTest
import RxSwift
import RxBlocking
import RxTest

final class ProductsViewModelTests: XCTestCase {
    private var viewModel: ProductsViewModel!
    private var navigator: ProductsNavigatorMock!
    private var useCase: ProductsUseCaseMock!
    
    private var input: ProductsViewModel.Input!
    private var output: ProductsViewModel.Output!
    
    private var disposeBag: DisposeBag!
    private var scheduler: TestScheduler!
    
    private var errorOutput: TestableObserver<Error>!
    private var isLoadingOutput: TestableObserver<Bool>!
    private var isReloadingOutput: TestableObserver<Bool>!
    private var isLoadingMoreOutput: TestableObserver<Bool>!
    private var productListOutput: TestableObserver<[ProductViewModel]>!
    private var selectedProductOutput: TestableObserver<Void>!
    private var editedProductOutput: TestableObserver<Void>!
    private var isEmptyOutput: TestableObserver<Bool>!
    private var deletedProductOutput: TestableObserver<Void>!
    
    private let loadTrigger = PublishSubject<Void>()
    private let reloadTrigger = PublishSubject<Void>()
    private let loadMoreTrigger = PublishSubject<Void>()
    private let selectProductTrigger = PublishSubject<IndexPath>()
    private let editProductTrigger = PublishSubject<IndexPath>()
    private let deleteProductTrigger = PublishSubject<IndexPath>()

    override func setUp() {
        super.setUp()
        navigator = ProductsNavigatorMock()
        useCase = ProductsUseCaseMock()
        viewModel = ProductsViewModel(navigator: navigator, useCase: useCase)
        
        input = ProductsViewModel.Input(
            loadTrigger: loadTrigger.asDriverOnErrorJustComplete(),
            reloadTrigger: reloadTrigger.asDriverOnErrorJustComplete(),
            loadMoreTrigger: loadMoreTrigger.asDriverOnErrorJustComplete(),
            selectProductTrigger: selectProductTrigger.asDriverOnErrorJustComplete(),
            editProductTrigger: editProductTrigger.asDriverOnErrorJustComplete(),
            deleteProductTrigger: deleteProductTrigger.asDriverOnErrorJustComplete()
        )
        
        output = viewModel.transform(input)
        
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0)
        
        errorOutput = scheduler.createObserver(Error.self)
        isLoadingOutput = scheduler.createObserver(Bool.self)
        isReloadingOutput = scheduler.createObserver(Bool.self)
        isLoadingMoreOutput = scheduler.createObserver(Bool.self)
        productListOutput = scheduler.createObserver([ProductViewModel].self)
        selectedProductOutput = scheduler.createObserver(Void.self)
        editedProductOutput = scheduler.createObserver(Void.self)
        isEmptyOutput = scheduler.createObserver(Bool.self)
        deletedProductOutput = scheduler.createObserver(Void.self)
        
        output.error.drive(errorOutput).disposed(by: disposeBag)
        output.isLoading.drive(isLoadingOutput).disposed(by: disposeBag)
        output.isReloading.drive(isReloadingOutput).disposed(by: disposeBag)
        output.isLoadingMore.drive(isLoadingMoreOutput).disposed(by: disposeBag)
        output.productList.drive(productListOutput).disposed(by: disposeBag)
        output.selectedProduct.drive(selectedProductOutput).disposed(by: disposeBag)
        output.isEmpty.drive(isEmptyOutput).disposed(by: disposeBag)
        output.editedProduct.drive(editedProductOutput).disposed(by: disposeBag)
        output.deletedProduct.drive(deletedProductOutput).disposed(by: disposeBag)
    }
    
    private func startTriggers(load: Recorded<Event<Void>>? = nil,
                               reload: Recorded<Event<Void>>? = nil,
                               loadMore: Recorded<Event<Void>>? = nil,
                               selectProduct: Recorded<Event<IndexPath>>? = nil,
                               editProduct: Recorded<Event<IndexPath>>? = nil,
                               deleteProduct: Recorded<Event<IndexPath>>? = nil) {
        if let load = load {
            scheduler.createColdObservable([load]).bind(to: loadTrigger).disposed(by: disposeBag)
        }
        
        if let reload = reload {
            scheduler.createColdObservable([reload]).bind(to: reloadTrigger).disposed(by: disposeBag)
        }
        
        if let loadMore = loadMore {
            scheduler.createColdObservable([loadMore]).bind(to: loadMoreTrigger).disposed(by: disposeBag)
        }
        
        if let selectProduct = selectProduct {
            scheduler.createColdObservable([selectProduct]).bind(to: selectProductTrigger).disposed(by: disposeBag)
        }
        
        if let editProduct = editProduct {
            scheduler.createColdObservable([editProduct]).bind(to: editProductTrigger).disposed(by: disposeBag)
        }
        
        if let deleteProduct = deleteProduct {
            scheduler.createColdObservable([deleteProduct]).bind(to: deleteProductTrigger).disposed(by: disposeBag)
        }
        
        scheduler.start()
    }

    func test_loadTriggerInvoked_getProductList() {
        // act
        startTriggers(load: .next(0, ()))
        
        // assert
        XCTAssert(useCase.getProductListCalled)
        XCTAssertEqual(productListOutput.lastEventElement?.count, 1)
    }

    func test_loadTriggerInvoked_getProductList_failedShowError() {
        // arrange
        useCase.getProductListReturnValue = Observable.error(TestError())

        // act
        startTriggers(load: .next(0, ()))

        // assert
        XCTAssert(useCase.getProductListCalled)
        XCTAssert(errorOutput.lastEventElement is TestError)
    }

    func test_reloadTriggerInvoked_getProductList() {
        // act
        startTriggers(reload: .next(0, ()))

        // assert
        XCTAssert(useCase.getProductListCalled)
        XCTAssertEqual(productListOutput.lastEventElement?.count, 1)
    }

    func test_reloadTriggerInvoked_getProductList_failedShowError() {
        // arrange
        useCase.getProductListReturnValue = Observable.error(TestError())

        // act
        startTriggers(reload: .next(0, ()))

        // assert
        XCTAssert(useCase.getProductListCalled)
        XCTAssert(errorOutput.lastEventElement is TestError)
    }

    func test_reloadTriggerInvoked_notGetProductListIfStillLoading() {
        // arrange
        useCase.getProductListReturnValue = Observable.never()

        // act
        loadTrigger.onNext(())
        useCase.getProductListCalled = false
        reloadTrigger.onNext(())

        // assert
        XCTAssertFalse(useCase.getProductListCalled)
    }

    func test_reloadTriggerInvoked_notGetProductListIfStillReloading() {
        // arrange
        useCase.getProductListReturnValue = Observable.never()

        // act
        reloadTrigger.onNext(())
        useCase.getProductListCalled = false
        reloadTrigger.onNext(())

        // assert
        XCTAssertFalse(useCase.getProductListCalled)
    }

    func test_loadMoreTriggerInvoked_loadMoreProductList() {
        // act
        startTriggers(load: .next(0, ()), loadMore: .next(10, ()))

        // assert
        XCTAssert(useCase.getProductListCalled)
        XCTAssertEqual(productListOutput.lastEventElement?.count, 2)
    }

    func test_loadMoreTriggerInvoked_loadMoreProductList_failedShowError() {
        // arrange
        useCase.getProductListReturnValue = Observable.error(TestError())

        // act
        startTriggers(load: .next(0, ()), loadMore: .next(10, ()))

        // assert
        XCTAssert(useCase.getProductListCalled)
        XCTAssert(errorOutput.lastEventElement is TestError)
    }

    func test_loadMoreTriggerInvoked_notLoadMoreProductListIfStillLoading() {
        // arrange
        useCase.getProductListReturnValue = Observable.never()

        // act
        loadTrigger.onNext(())
        useCase.getProductListCalled = false
        loadMoreTrigger.onNext(())

        // assert
        XCTAssertFalse(useCase.getProductListCalled)
    }

    func test_loadMoreTriggerInvoked_notLoadMoreProductListIfStillReloading() {
        // arrange
        useCase.getProductListReturnValue = Observable.never()

        // act
        reloadTrigger.onNext(())
        useCase.getProductListCalled = false
        loadMoreTrigger.onNext(())
        
        // assert
        XCTAssertFalse(useCase.getProductListCalled)
    }

    func test_loadMoreTriggerInvoked_notLoadMoreDocumentTypesStillLoadingMore() {
        // arrange
        useCase.getProductListReturnValue = Observable.never()

        // act
        loadMoreTrigger.onNext(())
        useCase.getProductListCalled = false
        loadMoreTrigger.onNext(())

        // assert
        XCTAssertFalse(useCase.getProductListCalled)
    }

    func test_selectProductTriggerInvoked_toProductDetail() {
        // act
        startTriggers(load: .next(0, ()), selectProduct: .next(10, IndexPath(row: 0, section: 0)))

        // assert
        XCTAssert(navigator.toProductDetailCalled)
    }
    
    func test_editProductTriggerInvoked_editProduct() {
        // act
        startTriggers(load: .next(0, ()), editProduct: .next(10, IndexPath(row: 0, section: 0)))

        // assert
        XCTAssert(navigator.toEditProductCalled)
    }
    
    func test_deletedProductInvoked_deleteProduct() {
        // act
        startTriggers(load: .next(0, ()), deleteProduct: .next(10, IndexPath(row: 0, section: 0)))

        // assert
        XCTAssert(navigator.confirmDeleteProductCalled)
        XCTAssert(useCase.deleteProductCalled)
    }
}

