#!/usr/bin/env python3
"""
OSM Overpass 데이터에서 서울 버스 노선 + 정류소 추출
입력:
  /tmp/bus_full.json - 노선 geometry (relation + way)
  /tmp/bus_stops_osm.json - 전체 정류소 (node)
출력:
  tools/bus_data_cache.json - dart 생성용 캐시
  assets/geojson/seoul_bus.geojson - 노선 시각화용
"""

import json
import math
from collections import defaultdict

ROUTES_FILE = '/tmp/bus_full.json'
STOPS_FILE = '/tmp/bus_stops_osm.json'
CACHE_OUTPUT = 'tools/bus_data_cache.json'
GEOJSON_OUTPUT = 'assets/geojson/seoul_bus.geojson'


def main():
    # ─── 1. Load route relations + geometry ───
    print('📂 Loading route data...')
    with open(ROUTES_FILE) as f:
        route_data = json.load(f)

    nodes_geo = {}  # id → {lat, lon}
    ways_geo = {}   # id → [node_ids]
    relations = []

    for e in route_data['elements']:
        if e['type'] == 'node':
            nodes_geo[e['id']] = (e.get('lat', 0), e.get('lon', 0))
        elif e['type'] == 'way':
            ways_geo[e['id']] = e.get('nodes', [])
        elif e['type'] == 'relation':
            relations.append(e)

    print(f'   Relations: {len(relations)}, Ways: {len(ways_geo)}, Nodes: {len(nodes_geo)}')

    # ─── 2. Load all bus stops ───
    print('📂 Loading bus stops...')
    with open(STOPS_FILE) as f:
        stops_data = json.load(f)

    all_stops = []
    for e in stops_data['elements']:
        tags = e.get('tags', {})
        name = tags.get('name', tags.get('name:ko', ''))
        if not name:
            continue
        all_stops.append({
            'id': e['id'],
            'name': name,
            'lat': e['lat'],
            'lon': e['lon'],
            'arsId': tags.get('ref', ''),
            'route_ref': tags.get('route_ref', ''),
        })

    print(f'   Bus stops: {len(all_stops)}')

    # Build route_ref → stops mapping
    route_stops_map = defaultdict(list)  # route_ref string → [stops]
    for stop in all_stops:
        route_ref = stop['route_ref']
        if route_ref:
            # route_ref can be "143;301;402" format
            for ref in route_ref.replace(',', ';').split(';'):
                ref = ref.strip()
                if ref:
                    route_stops_map[ref].append(stop)

    print(f'   Routes with stop data: {len(route_stops_map)}')

    # ─── 3. Process route relations ───
    print('\n🚌 Processing routes...')

    # Filter Seoul bus routes from relations
    seoul_relations = {}  # ref → relation
    for rel in relations:
        tags = rel.get('tags', {})
        if tags.get('route') != 'bus':
            continue
        ref = tags.get('ref', '')
        if not ref:
            continue

        name = tags.get('name', '')
        network = tags.get('network', '')
        operator = tags.get('operator', '')

        is_seoul = ('서울' in name or '서울' in network or
                    '간선' in network or '지선' in name or
                    '마을' in name or '마을' in network or
                    '서울' in operator)
        is_gyeonggi = '경기' in network or '경기' in operator or '경기' in name

        if is_gyeonggi:
            continue

        if not is_seoul:
            try:
                num = int(ref)
                if 100 <= num <= 9999:
                    is_seoul = True
            except ValueError:
                if ref.startswith('N') or ref.startswith('M'):
                    is_seoul = True

        if is_seoul and ref not in seoul_relations:
            seoul_relations[ref] = rel

    print(f'   Seoul route relations: {len(seoul_relations)}')

    # Also add routes from route_stops_map that we don't have relations for
    all_route_refs = set(seoul_relations.keys()) | set(route_stops_map.keys())
    # Filter route_stops_map refs to Seoul-like patterns
    seoul_refs = set()
    for ref in all_route_refs:
        try:
            num = int(ref)
            if 1 <= num <= 9999:
                seoul_refs.add(ref)
        except ValueError:
            if ref.startswith('N') or ref.startswith('M') or ref.startswith('0'):
                seoul_refs.add(ref)
            # 마을버스: 서대문01, 강남05 등
            elif any(c.isdigit() for c in ref):
                seoul_refs.add(ref)

    print(f'   Total Seoul route refs (relations + stops): {len(seoul_refs)}')

    # ─── 4. Build route geometry (GeoJSON) ───
    geojson_features = []
    route_geometries = {}  # ref → [[lon, lat], ...]

    for ref, rel in seoul_relations.items():
        if ref not in seoul_refs:
            continue

        members = rel.get('members', [])
        way_coords = []
        for m in members:
            if m['type'] == 'way' and m.get('role', '') in ('', 'forward', 'backward', 'route'):
                wid = m['ref']
                if wid in ways_geo:
                    coords = []
                    for nid in ways_geo[wid]:
                        if nid in nodes_geo:
                            lat, lon = nodes_geo[nid]
                            coords.append([lon, lat])
                    if coords:
                        way_coords.append(coords)

        merged = _merge_ways(way_coords)
        if merged:
            route_geometries[ref] = merged
            tags = rel.get('tags', {})
            geojson_features.append({
                'type': 'Feature',
                'properties': {
                    'ref': ref,
                    'name': tags.get('name', ref),
                    'routeType': _get_route_type(tags, ref),
                },
                'geometry': {
                    'type': 'LineString',
                    'coordinates': merged,
                }
            })

    print(f'   Routes with geometry: {len(route_geometries)}')

    # ─── 5. Build final route data ───
    final_routes = {}

    for ref in sorted(seoul_refs):
        stops = route_stops_map.get(ref, [])
        rel = seoul_relations.get(ref)
        geometry = route_geometries.get(ref)

        # Need at least 2 stops to be useful for pathfinding
        if len(stops) < 2:
            continue

        # Order stops along route geometry if available
        if geometry:
            stops = _order_stops_along_geometry(stops, geometry)
        else:
            # No geometry - just use stops as-is (order by latitude as rough approximation)
            stops.sort(key=lambda s: (s['lat'], s['lon']))

        # Determine route type
        tags = rel.get('tags', {}) if rel else {}
        route_type = _get_route_type(tags, ref)

        # Route name
        route_name = ref
        start_station = stops[0]['name'] if stops else ''
        end_station = stops[-1]['name'] if stops else ''

        final_routes[ref] = {
            'info': {
                'busRouteId': str(rel['id']) if rel else ref,
                'busRouteNm': route_name,
                'routeType': route_type,
                'stStationNm': start_station,
                'edStationNm': end_station,
                'term': 0,
            },
            'stations': [
                {
                    'seq': i + 1,
                    'stId': str(s['id']),
                    'arsId': s.get('arsId', ''),
                    'stNm': s['name'],
                    'lat': s['lat'],
                    'lng': s['lon'],
                }
                for i, s in enumerate(stops)
            ],
        }

    print(f'\n✅ Final routes: {len(final_routes)}')
    total_stops = sum(len(r['stations']) for r in final_routes.values())
    print(f'   Total stop records: {total_stops}')
    avg_stops = total_stops / len(final_routes) if final_routes else 0
    print(f'   Avg stops/route: {avg_stops:.1f}')

    # Stats by type
    type_counts = defaultdict(int)
    for r in final_routes.values():
        rt = r['info']['routeType']
        type_counts[rt] += 1
    type_names = {3: '간선', 4: '지선', 5: '순환', 6: '광역'}
    for t, c in sorted(type_counts.items()):
        print(f'   {type_names.get(t, "기타")}({t}): {c}개')

    # ─── 6. Save outputs ───
    cache = {
        'routeList': [r['info'] for r in final_routes.values()],
        'routes': final_routes,
        'source': 'OpenStreetMap via Overpass API',
        'generated': '2026-05-06',
    }
    with open(CACHE_OUTPUT, 'w') as f:
        json.dump(cache, f, ensure_ascii=False, indent=2)
    print(f'\n📄 Cache: {CACHE_OUTPUT}')

    geojson = {
        'type': 'FeatureCollection',
        'features': geojson_features,
    }
    with open(GEOJSON_OUTPUT, 'w') as f:
        json.dump(geojson, f, ensure_ascii=False)

    import os
    size_mb = os.path.getsize(GEOJSON_OUTPUT) / 1024 / 1024
    print(f'📄 GeoJSON: {GEOJSON_OUTPUT} ({size_mb:.1f} MB)')
    size_cache = os.path.getsize(CACHE_OUTPUT) / 1024 / 1024
    print(f'📄 Cache size: {size_cache:.1f} MB')


def _get_route_type(tags, ref):
    name = tags.get('name', '')
    network = tags.get('network', '')

    if '마을' in name or '마을' in network:
        return 4
    if '간선' in name or '간선' in network:
        return 3
    if '광역' in name or '광역' in network:
        return 6
    if '순환' in name or '순환' in network:
        return 5

    try:
        num = int(ref)
        if 100 <= num <= 999:
            return 3  # 간선
        elif 1000 <= num <= 9999:
            return 4  # 지선
    except ValueError:
        pass

    if ref.startswith('N'):
        return 3
    if ref.startswith('M'):
        return 6

    return 4  # default


def _order_stops_along_geometry(stops, geometry):
    """Order stops by their projection onto the route geometry."""
    if not geometry or not stops:
        return stops

    # For each stop, find the closest point on the geometry and its parameter
    stop_params = []
    for stop in stops:
        min_dist = float('inf')
        best_param = 0
        accumulated = 0

        for i in range(len(geometry) - 1):
            seg_start = geometry[i]
            seg_end = geometry[i + 1]
            seg_len = _dist(seg_start, seg_end)

            # Project stop onto segment
            proj = _project_on_segment(stop['lon'], stop['lat'], seg_start, seg_end)
            d = _dist([stop['lon'], stop['lat']], proj)

            if d < min_dist:
                min_dist = d
                # Parameter along entire route
                seg_frac = _dist(seg_start, proj) / seg_len if seg_len > 0 else 0
                best_param = accumulated + seg_frac * seg_len

            accumulated += seg_len

        stop_params.append((best_param, min_dist, stop))

    # Sort by parameter (position along route)
    stop_params.sort(key=lambda x: x[0])

    # Filter out stops too far from route (> ~500m ≈ 0.005 degrees)
    result = [sp[2] for sp in stop_params if sp[1] < 0.005]
    return result if result else stops


def _project_on_segment(px, py, seg_start, seg_end):
    """Project point onto line segment."""
    sx, sy = seg_start
    ex, ey = seg_end
    dx, dy = ex - sx, ey - sy
    seg_len_sq = dx * dx + dy * dy

    if seg_len_sq == 0:
        return seg_start

    t = max(0, min(1, ((px - sx) * dx + (py - sy) * dy) / seg_len_sq))
    return [sx + t * dx, sy + t * dy]


def _dist(a, b):
    return math.sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2)


def _merge_ways(way_coords):
    """Merge way coordinate arrays into a single continuous line."""
    if not way_coords:
        return []

    merged = list(way_coords[0])

    for segment in way_coords[1:]:
        if not segment:
            continue
        if not merged:
            merged = list(segment)
            continue

        last = merged[-1]
        if _close(last, segment[0]):
            merged.extend(segment[1:])
        elif _close(last, segment[-1]):
            merged.extend(list(reversed(segment))[1:])
        elif _close(merged[0], segment[-1]):
            merged = list(segment[:-1]) + merged
        elif _close(merged[0], segment[0]):
            merged = list(reversed(segment))[:-1] + merged
        else:
            merged.extend(segment)

    return merged


def _close(a, b, threshold=0.0001):
    return abs(a[0] - b[0]) < threshold and abs(a[1] - b[1]) < threshold


if __name__ == '__main__':
    main()
