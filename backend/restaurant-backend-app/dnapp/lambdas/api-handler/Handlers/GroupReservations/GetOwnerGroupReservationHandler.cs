using Amazon.Lambda.APIGatewayEvents;
using Amazon.Lambda.Core;
using APIHandler.Exceptions;
using APIHandler.Helpers;
using APIHandler.Models.GuestReservation;
using APIHandler.Services.GroupReservations;
using System.Threading.Tasks;

namespace APIHandler.Handlers.GroupReservations;

/// <summary>
/// Owner-only: details of the group reservation (same shape as GET /guest/invites/{token}),
/// available even when the group is full or already submitted.
/// </summary>
public class GetOwnerGroupReservationHandler(IGroupReservationService service) : IApiRequestHandler
{
    public async Task<APIGatewayProxyResponse> HandleRequest(APIGatewayProxyRequest request, ILambdaContext context)
    {
        if (!request.TryGetPathValue("reservationId", out string? reservationId))
            return ResponseBuilder.CreateErrorResponse(400, "Missing 'reservationId' in path parameters.", context.Logger);

        if (request.RequestContext?.Authorizer?.Claims == null ||
            !request.RequestContext.Authorizer.Claims.TryGetValue("sub", out string? userId))
            return ResponseBuilder.CreateErrorResponse(401, "Unauthorized.", context.Logger);

        try
        {
            GetGroupReservationResponse result = await service.GetOwnerGroupReservationAsync(userId, reservationId);
            return ResponseBuilder.CreateSuccessResponse(result);
        }
        catch (GroupReservationNotFoundException exception)
        {
            return ResponseBuilder.CreateErrorResponse(404, exception.Message, context.Logger);
        }
        catch (ReservationNotFoundException exception)
        {
            return ResponseBuilder.CreateErrorResponse(404, exception.Message, context.Logger);
        }
        catch (ActionForbiddenException exception)
        {
            return ResponseBuilder.CreateErrorResponse(403, exception.Message, context.Logger);
        }
        catch (ValidationException exception)
        {
            return ResponseBuilder.CreateErrorCodeResponse(exception);
        }
    }
}
