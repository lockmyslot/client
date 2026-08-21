class ApiConstants {
  static String baseUrl = 'http://192.168.1.6:3000/api/v1';

  // Auth
  static const String register = '/auth/register';
  static const String me = '/auth/me';

  // Groups
  static const String groups = '/groups';
  static const String joinGroup = '/groups/join';
  static String groupDetail(String id) => '/groups/$id';
  static String groupMembers(String id) => '/groups/$id/members';
  static String removeMember(String groupId, String userId) =>
      '/groups/$groupId/members/$userId';
  static String leaveGroup(String id) => '/groups/$id/leave';
  static String regenerateInvite(String id) => '/groups/$id/regenerate_invite';

  // Resources
  static String resources(String groupId) => '/groups/$groupId/resources';
  static String resourceDetail(String groupId, String resourceId) =>
      '/groups/$groupId/resources/$resourceId';

  // Booking Rules
  static String bookingRules(String groupId, String resourceId) =>
      '/groups/$groupId/resources/$resourceId/rules';

  // Bookings & Availability
  static String availability(String groupId, String resourceId) =>
      '/groups/$groupId/resources/$resourceId/availability';
  static String bookings(String groupId, String resourceId) =>
      '/groups/$groupId/resources/$resourceId/bookings';
  static String cancelBooking(String groupId, String bookingId) =>
      '/groups/$groupId/bookings/$bookingId';
  static String myBookings(String groupId) => '/groups/$groupId/my_bookings';
}
