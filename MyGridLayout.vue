<template>
  <v-container fluid>
    <v-row justify="center">
      <v-col cols="12" md="4">
        <v-text-field
            v-model="columnCount"
            label="每列数量"
            type="number"
            min="1"
            max="12"
        ></v-text-field>
      </v-col>
    </v-row>
    <v-row justify="center">
      <v-col>
        <div ref="gridContainer" class="grid-stack"></div>
      </v-col>
    </v-row>
  </v-container>
</template>

<script lang="ts" setup>
import {ref, onMounted, watch, computed} from 'vue';
import {GridStack} from 'gridstack';
import 'gridstack/dist/gridstack.min.css';
import 'gridstack/dist/gridstack-extra.css';

const gridContainer = ref<HTMLDivElement | null>(null);
const items = [
  {icon: 'fa-solid fa-coffee', text: 'Coffee'},
  {icon: 'fa-solid fa-apple-alt', text: 'Apple'},
  {icon: 'fa-solid fa-bell', text: 'Bell'},
  {icon: 'fa-solid fa-camera', text: 'Camera'},
  {icon: 'fa-solid fa-envelope', text: 'Mail'},
  {icon: 'fa-solid fa-heart', text: 'Heart'},
  {icon: 'fa-solid fa-star', text: 'Star'},
  {icon: 'fa-solid fa-music', text: 'Music'},
  {icon: 'fa-solid fa-film', text: 'Film'},
  {icon: 'fa-solid fa-gamepad', text: 'Game'},
  {icon: 'fa-solid fa-book', text: 'Book'},
  {icon: 'fa-solid fa-car', text: 'Car'},
  {icon: 'fa-solid fa-tree', text: 'Tree'},
  {icon: 'fa-solid fa-plane', text: 'Plane'},
  {icon: 'fa-solid fa-hospital', text: 'Hospital'},
  {icon: 'fa-solid fa-home', text: 'Home'},
  {icon: 'fa-solid fa-key', text: 'Key'},
  {icon: 'fa-solid fa-lightbulb', text: 'Idea'},
  {icon: 'fa-solid fa-map', text: 'Map'},
  {icon: 'fa-solid fa-paint-brush', text: 'Paint'},
  {icon: 'fa-solid fa-shopping-cart', text: 'Cart'},
  {icon: 'fa-solid fa-tv', text: 'TV'},
  {icon: 'fa-solid fa-wifi', text: 'WiFi'},
  {icon: 'fa-solid fa-wrench', text: 'Tool'},
  {icon: 'fa-solid fa-graduation-cap', text: 'Study'},
  {icon: 'fa-solid fa-rocket', text: 'Rocket'},
  {icon: 'fa-solid fa-gift', text: 'Gift'},
  {icon: 'fa-solid fa-phone', text: 'Phone'},
  {icon: 'fa-solid fa-sun', text: 'Sun'},
  {icon: 'fa-solid fa-moon', text: 'Moon'},
  {icon: 'fa-solid fa-cloud', text: 'Cloud'},
  {icon: 'fa-solid fa-water', text: 'Water'},
  {icon: 'fa-solid fa-fire', text: 'Fire'},
  {icon: 'fa-solid fa-leaf', text: 'Leaf'},
  {icon: 'fa-solid fa-snowflake', text: 'Snow'},
  {icon: 'fa-solid fa-wind', text: 'Wind'},
  {icon: 'fa-solid fa-mountain', text: 'Mountain'},
  {icon: 'fa-solid fa-tree-palm', text: 'Palm'},
  {icon: 'fa-solid fa-anchor', text: 'Anchor'},
  {icon: 'fa-solid fa-binoculars', text: 'Binoculars'},
  {icon: 'fa-solid fa-bolt', text: 'Bolt'},
  {icon: 'fa-solid fa-cogs', text: 'Cogs'},
  {icon: 'fa-solid fa-magnet', text: 'Magnet'},
  {icon: 'fa-solid fa-microchip', text: 'Chip'},
  {icon: 'fa-solid fa-robot', text: 'Robot'}
];

const columnCount = ref<number>(4); // 初始列数为3

const computedCols = computed(() => {
  const totalCols = 12; // Vuetify 网格系统总列数
  return Math.min(totalCols, columnCount.value);
});

const updateGrid = () => {
  if (gridContainer.value) {
    const grid = GridStack.init({
      float: true,
      cellHeight: 'auto',
      resizable: {
        handles: 'e, se, s, sw, w'
      }
    }, gridContainer.value);

    const gridItems = items.map((item, index) => ({
      w: 1, // 设置每个单元的宽度
      h: 1,
      column:columnCount.value,
      content: `<div class="grid-stack-item-content">
                  <i class="${item.icon}"></i>
                  <div>${item.text}</div>
                </div>`
    }));

    grid.column(computedCols.value);
    grid.load(gridItems); // 加载新的项目

    console.log(grid)

  }
};

onMounted(updateGrid);

watch(columnCount, updateGrid);

</script>

<style scope>


</style>






