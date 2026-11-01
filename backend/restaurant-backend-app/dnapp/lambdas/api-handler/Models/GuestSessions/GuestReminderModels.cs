using System.Collections.Generic;
using System.Text.Json.Serialization;

namespace APIHandler.Models.GuestSessions;

/// <summary>Body is optional: without guestSessionId every guest who is still choosing gets a reminder.</summary>
public record RemindGuestsRequest(
    [property: JsonPropertyName("guestSessionId")] string? GuestSessionId);

public record ReminderTargetResponse(
    [property: JsonPropertyName("guestSessionId")] string GuestSessionId,
    [property: JsonPropertyName("guestName")] string GuestName);

public record SkippedReminderResponse(
    [property: JsonPropertyName("guestSessionId")] string GuestSessionId,
    [property: JsonPropertyName("guestName")] string GuestName,
    [property: JsonPropertyName("reason")] string Reason);

public record RemindGuestsResponse(
    [property: JsonPropertyName("reminded")] IReadOnlyList<ReminderTargetResponse> Reminded,
    [property: JsonPropertyName("skipped")] IReadOnlyList<SkippedReminderResponse> Skipped);
