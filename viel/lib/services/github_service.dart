import 'dart:convert';
import 'package:http/http.dart' as http;

class GithubService {
  /// Fetches the total number of Pull Requests created by a user
  static Future<int> fetchPullRequestCount(String username) async {
    try {
      // Use GitHub's Search API to find PRs authored by the user
      final url = Uri.parse('https://api.github.com/search/issues?q=type:pr+author:$username');
      
      final response = await http.get(url, headers: {
        'Accept': 'application/vnd.github.v3+json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['total_count'] ?? 0;
      } else {
        throw Exception('Failed to fetch GitHub PRs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network or API error: $e');
    }
  }
}
