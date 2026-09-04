# Questory technical reference

This file preserves the dependency, asset-license, destination-source, and
verification notes used by the project and report.

## Dependency and asset review

Reviewed: 2 September 2026. `pubspec.lock` is the reproducible source for the
complete resolved dependency graph.

| Direct package | Resolved | Purpose | License | Offline behavior |
| --- | ---: | --- | --- | --- |
| `camera` | 0.10.6 | Quest evidence capture | BSD 3-Clause | Device only |
| `geolocator` | 14.0.3 | GPS and permission state | MIT | Device only |
| `path_provider` | 2.1.6 | Private photo/export locations | BSD 3-Clause | Local only |
| `sqflite` | 2.4.2+1 | Runs, stories, achievements | BSD 2-Clause | Local only |
| `sqflite_common_ffi` | 2.4.2+1 | SQLite repository tests | BSD 2-Clause | Test only |
| `cupertino_icons` | 1.0.9 | Flutter icons | MIT | Bundled |

The Android minimum SDK is 24. No package requires network access for the
offline MVP. Story Studio bundles Noto Sans and Space Grotesk; their OFL texts
are stored beside the font files. Destination artwork and JSON content are
team-authored. Flutter supplies Material icons. The inherited MIT attribution
remains in `LICENSE`.

## Destination content review

Questory routes are approximate bundled suggestions, not turn-by-turn
navigation or safety guarantees. Users are instructed to remain in public
pedestrian areas, obey current signs and designated crossings, and stop when
traffic, weather, construction, crowds, or events make a route unsuitable.
Every quest may be skipped.

### Nha Trang

The Coastal Morning Run follows the central Tran Phu waterfront. Vietnam
Tourism describes Tran Phu Beach as the central beach with a promenade,
sculpture gardens, and ornamental planting. Khanh Hoa reporting also documents
a public 2026 walking event from the Tram Huong Tower area along Tran Phu.

Sources:

- https://www.vietnam.travel/things-to-do/nha-trang-best-beaches-sustainable-vacation
- https://baokhanhhoa.vn/the-thao/the-thao-trong-nuoc/202601/hon-400-gia-dinh-tham-gia-giai-di-bo-long-chau-ngay-hoi-gia-dinh-2026-7ec55d7/

### Ho Chi Minh City

The River and City Lights route links Nguyen Hue Walking Street and Bach Dang
Park. Tourism and government sources describe both as public walking,
recreation, and riverfront spaces. Because crossings and construction can
change, the pack requires the currently designated crossing or pedestrian
bridge instead of assuming a particular bridge is open.

Sources:

- https://visithcmc.net/en/news/du-lich-quan-1
- https://tphcm.baochinhphu.vn/dien-mao-moi-cong-vien-ben-bach-dang-thu-hut-du-khach-101220221185527255.htm
- https://ttbc-hcm.gov.vn/tp-hcm-xay-2-cau-di-bo-noi-pho-di-bo-nguyen-hue-voi-ben-bach-dang-1020194.html

## Verification boundary

The text and approximate geometry were desk-reviewed, and automated tests check
that each declared distance agrees with its bundled polyline. Neither route has
received an on-foot field inspection by the team. Current signs, access,
weather, construction, and events always take priority.
