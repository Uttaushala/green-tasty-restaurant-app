using APIHandler.Models.Orders;
using System.Collections.Generic;

using System;

namespace APIHandler.Models.GuestSessions;

public record GetGuestSessionResponse(
    string Name,
    IEnumerable<OrderItemResponse> Items,
    decimal Total,
    bool IsSubmitted,
    DateTime? ReminderAt = null);
