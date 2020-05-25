import myImage from '../../assets/images/map_pin.png';

const initMap = () => {
  if (document.querySelector('#map')) {
    mapboxgl.accessToken = 'pk.eyJ1IjoiY2hlem1hdXJpY2UiLCJhIjoiY2s5b2pqazIyMDFhMjNncDlxbTAzcGU1NyJ9.qS_hauRluV4nopWAd7q0Fg';
    var map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/mapbox/light-v10',
      center: [2.391959, 48.854435],
      zoom: 11
    });

    map.on("load", function () {
      /* Image: An image is loaded and added to the map. */
      map.loadImage(myImage, function(error, image) {
        if (error) throw error;
        map.addImage("custom-marker", image);
        /* Style layer: A style layer ties together the source and image and specifies how they are displayed on the map. */
        map.addLayer({
          id: "markers",
          type: "symbol",
          /* Source: A data source specifies the geographic coordinate where the image marker gets placed. */
          source: {
            type: "geojson",
            data: {
              type: 'FeatureCollection',
              features: [
              {
                type: 'Feature',
                properties: {},
                geometry: {
                  type: "Point",
                  coordinates: [2.391959, 48.854435]
                }
              }
              ]
            }
          },
          layout: {
            "icon-image": "custom-marker",
          }
        });
      });
    });
  }
};

const initMap2 = () => {
  if (document.querySelector('#map')) {
    mapboxgl.accessToken = 'pk.eyJ1IjoiY2hlem1hdXJpY2UiLCJhIjoiY2s5b2pqazIyMDFhMjNncDlxbTAzcGU1NyJ9.qS_hauRluV4nopWAd7q0Fg';
    var map = new mapboxgl.Map({
      container: 'map2',
      style: 'mapbox://styles/mapbox/light-v10',
      center: [2.391959, 48.854435],
      zoom: 11
    });

    map.on("load", function () {
      /* Image: An image is loaded and added to the map. */
      map.loadImage(myImage, function(error, image) {
        if (error) throw error;
        map.addImage("custom-marker", image);
        /* Style layer: A style layer ties together the source and image and specifies how they are displayed on the map. */
        map.addLayer({
          id: "markers",
          type: "symbol",
          /* Source: A data source specifies the geographic coordinate where the image marker gets placed. */
          source: {
            type: "geojson",
            data: {
              type: 'FeatureCollection',
              features: [
              {
                type: 'Feature',
                properties: {},
                geometry: {
                  type: "Point",
                  coordinates: [2.391959, 48.854435]
                }
              }
              ]
            }
          },
          layout: {
            "icon-image": "custom-marker",
          }
        });
      });
    });
  }
};

export { initMap, initMap2 };
