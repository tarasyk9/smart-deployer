import { defineConfig } from 'vocs/config'
import { sidebar } from './vocs.sidebar'

export default defineConfig({
  title: 'Documentation',

  basePath: '/smart-deployer',

  editLink: {
    link: (path) =>
    `https://github.com/tarasyk9/smart-deployer/edit/main/docs/src/pages/${path}`,
    text: 'Suggest changes to this page',
  },

  sidebar,
})