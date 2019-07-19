<script>
  import { onMount } from 'svelte';
  export let param;
  onMount(() => console.log('App ready ' + param));
</script>

<style>
  .my_div {
    background-color: red;
  }
</style>

<div class='my_div'>
</div>