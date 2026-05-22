import Foundation

final class LoadDiscogsMasterHandler: IHandler {
    private let networkUtility: NetworkUtility

    init(networkUtility: NetworkUtility) {
        self.networkUtility = networkUtility
    }

    func handle(_ request: RequestBase) async -> ResponseBase {
        guard let req = request as? LoadDiscogsMasterRequest else {
            return UnhandledRequestResponse(correlationId: request.correlationId,
                                           requestType: String(describing: type(of: request)))
        }
        do {
            guard let url = URL(string: "\(DiscogsAPI.masterURL)/\(req.masterId)") else {
                return LoadDiscogsMasterResponse(correlationId: req.correlationId,
                                                errorMessage: NetworkError.invalidURL.localizedDescription)
            }
            let data = try await networkUtility.get(url: url,
                                                    headers: DiscogsAPI.headers(token: req.token))
            let decoded = try JSONDecoder().decode(DiscogsMasterAPIResponse.self, from: data)
            return LoadDiscogsMasterResponse(correlationId: req.correlationId,
                                            mainReleaseId: decoded.mainRelease)
        } catch {
            return LoadDiscogsMasterResponse(correlationId: req.correlationId,
                                            errorMessage: error.localizedDescription)
        }
    }
}

private struct DiscogsMasterAPIResponse: Decodable {
    let mainRelease: Int

    enum CodingKeys: String, CodingKey {
        case mainRelease = "main_release"
    }
}
