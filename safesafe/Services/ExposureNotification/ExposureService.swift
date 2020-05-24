//
//  ExposureService.swift
//  safesafe
//
//  Created by Rafał Małczyński on 13/05/2020.
//

import ExposureNotification
import PromiseKit

@available(iOS 13.5, *)
protocol ExposureServiceProtocol: class {
    
    var isExposureNotificationAuthorized: Bool { get }
    var isExposureNotificationEnabled: Bool { get }
    
    func activateManager() -> Promise<ENStatus>
    func setExposureNotificationEnabled(_ setEnabled: Bool) -> Promise<Void>
    func getDiagnosisKeys() -> Promise<[ENTemporaryExposureKey]>
    func detectExposures() -> Promise<Void>
    
}

@available(iOS 13.5, *)
final class ExposureService: ExposureServiceProtocol {
    
    // MARK: - Properties
    
    private let exposureManager: ENManager
    private let diagnosisKeysService: DiagnosisKeysDownloadServiceProtocol
    
    private var isCurrentlyDetectingExposures = false
    
    var isExposureNotificationAuthorized: Bool {
        ENManager.authorizationStatus == .authorized
    }
    
    var isExposureNotificationEnabled: Bool {
        exposureManager.exposureNotificationEnabled
    }
    
    // MARK: - Life Cycle
    
    init(
        exposureManager: ENManager,
        diagnosisKeysService: DiagnosisKeysDownloadServiceProtocol
    ) {
        self.exposureManager = exposureManager
        self.diagnosisKeysService = diagnosisKeysService
        activateManager()
    }
    
    deinit {
        exposureManager.invalidate()
    }
    
    // MARK: - Public methods
    
    @discardableResult
    func activateManager() -> Promise<ENStatus> {
        guard exposureManager.exposureNotificationStatus == .unknown else {
            return .value(exposureManager.exposureNotificationStatus)
        }
        
        return Promise { [weak self] seal in
            guard let self = self else {
                return seal.reject(InternalError.deinitialized)
            }
            self.exposureManager.activate { error in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(self.exposureManager.exposureNotificationStatus)
                }
            }
        }
    }
    
    func setExposureNotificationEnabled(_ setEnabled: Bool) -> Promise<Void> {
        Promise { [weak self] seal in
            self?.exposureManager.setExposureNotificationEnabled(setEnabled) { error in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(())
                }
            }
        }
    }
    
    func getDiagnosisKeys() -> Promise<[ENTemporaryExposureKey]> {
        Promise { [weak self] seal in
            let completion: ENGetDiagnosisKeysHandler = { exposureKeys, error in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill(exposureKeys ?? [])
                }
            }
            
            #if DEV || STAGE
            self?.exposureManager.getTestDiagnosisKeys(completionHandler: completion)
            #else
            self?.exposureManager.getDiagnosisKeys(completionHandler: completion)
            #endif
        }
    }
    
    func detectExposures() -> Promise<Void> {
        guard !isCurrentlyDetectingExposures else {
            return .value
        }
        isCurrentlyDetectingExposures = true
        
        // TODO: Should ask KeysService for configuration and key urls here
        var serviceClosure: (Swift.Result<(ENExposureConfiguration, [URL]), Error>) -> Void
        
        serviceClosure = { [weak self] result in
            switch result {
            case let .failure(error):
                self?.endExposureSession(with: .failure(error))
                //completion(.failure(error))
                
            case let .success((configuration, urls)):
                self?.exposureManager.detectExposures(configuration: configuration, diagnosisKeyURLs: urls) { summary, error in
                    guard let summary = summary, error == nil else {
                        self?.endExposureSession(with: .failure(error!))
                        //completion(.failure(error!))
                        return
                    }
                    
                    //self?.getExposureInfo(from: summary, completion)
                }
            }
            
        }
        
        // TODO: Implement proper logic when KeysService is finished
        return Promise()
    }
    
    // MARK: - Private methods
    
    private func getExposureInfo(
        from summary: ENExposureDetectionSummary,
        _ completion: @escaping (Swift.Result<Void, Error>) -> Void
    ) {
        let userExplanation = "Some explanation for the user, that their exposure details are being reveled to the app"
        
        exposureManager.getExposureInfo(summary: summary, userExplanation: userExplanation) { [weak self] exposureInfo, error in
            guard let info = exposureInfo, error == nil else {
                self?.endExposureSession(with: .failure(error!))
                completion(.failure(error!))
                return
            }
            
            // Map ENExposureInfo to some domain model - to discuss
            self?.endExposureSession(with: .success)
            completion(.success)
        }
    }
    
    // TODO: Some other successful result should be here - to discuss (probably `[Exposure]` like in Apple's sample)
    private func endExposureSession(with result: Swift.Result<Void, Error>) {
        
    }
    
}
